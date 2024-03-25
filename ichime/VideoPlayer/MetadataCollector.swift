//
//  MetadataCollector.swift
//  Ichime
//
//  Created by Nikita Nafranets on 25.03.2024.
//

import Anime365ApiClient
import AVFoundation
import Foundation
import UIKit

struct MetadataPlayer {
    /** большой заголовок в плеере */
    let title: String?
    /** надпись над заголовком */
    let subtitle: String?
    /** текст который открывается если нажать на title */
    let description: String?
    let genre: String?
    let rating: String?
    let image: Data?
    let year: String?
}

struct MetadataCollector {
    let api: Anime365ApiClient
    let episodeId: Int
    let translationId: Int

    init(episodeId: Int, translationId: Int, api: Anime365ApiClient = ApplicationDependency.container.resolve()) {
        self.episodeId = episodeId
        self.translationId = translationId
        self.api = api
    }

    static func createMetadataItems(for metadata: MetadataPlayer) -> [AVMetadataItem] {
        let mapping: [AVMetadataIdentifier: Any?] = [
            .commonIdentifierTitle: metadata.title,
            .iTunesMetadataTrackSubTitle: metadata.subtitle,
            .commonIdentifierArtwork: metadata.image != nil ? (UIImage(data: metadata.image!)?.pngData() as Any) : nil,
            .commonIdentifierDescription: metadata.description,
            .iTunesMetadataContentRating: metadata.rating,
            .quickTimeMetadataGenre: metadata.genre,
            .quickTimeMetadataYear: "2010",
            .id3MetadataYear: "2012",
            .id3MetadataOriginalReleaseYear: "2014",
            .identifier3GPUserDataRecordingYear: "2018",
        ]

        return mapping.compactMap { createMetadataItem(for: $0, value: $1) }
    }

    private static func createMetadataItem(for identifier: AVMetadataIdentifier,
                                           value: Any?) -> AVMetadataItem?
    {
        guard let value else { return nil }
        let item = AVMutableMetadataItem()
        item.identifier = identifier
        item.value = value as? NSCopying & NSObjectProtocol
        // Specify "und" to indicate an undefined language.
        item.extendedLanguageTag = "und"
        return item.copy() as! AVMetadataItem
    }

    func getMetadata() async -> MetadataPlayer? {
        do {
            let episodeData = try await api.sendApiRequest(GetEpisodeRequest(episodeId: episodeId))
            let showData = try await api.sendApiRequest(GetSeriesRequest(seriesId: episodeData.seriesId))
            let translation = episodeData.translations.first(where: { $0.id == translationId })

            var description = ""

            if let translation {
                description = """
                Переведено командой: \(translation.authorsSummary)
                Описание:
                \(showData.descriptions?.first?.value ?? "Описания нет")
                """
            }

            var image: Data? = nil

            if let imageURL = URL(string: showData.posterUrl) {
                do {
                    let (data, _) = try await URLSession.shared.data(from: imageURL)
                    image = data
                } catch {
                    print("cannot download image for meta \(error)")
                }
            }

            print(showData.season)
            print(showData.year)
            return .init(
                title: episodeData.episodeFull,
                subtitle: showData.titles.romaji ?? showData.title,
                description: description,
                genre: "Китайские геи",
                rating: "8 из 10",
                image: image,
                year: showData.season
            )
        } catch {
            print("Cannot download metadata \(error)")
            return nil
        }
    }
}
