//
//  MetadataCollector.swift
//  Ichime
//
//  Created by Nikita Nafranets on 25.03.2024.
//

import Anime365ApiClient
import AVFoundation
import Foundation

struct MetadataCollector {
    let api: Anime365ApiClient
    let episodeId: Int
    let translationId: Int

    init(episodeId: Int, translationId: Int, api: Anime365ApiClient = ApplicationDependency.container.resolve()) {
        self.episodeId = episodeId
        self.translationId = translationId
        self.api = api
    }

    /**
        @param title большой заголовок в плеере
        @param subtitle надпись над заголовком
        @param descrtiption текст который открывается если нажать на title
     */
    static func createMetadata(title: String?, subtitle: String?, description: String?) -> [AVMetadataItem] {
        var metadata: [AVMetadataItem] = []
        if let title {
            let titleItem = AVMutableMetadataItem()
            titleItem.identifier = .commonIdentifierTitle
            titleItem.value = NSString(string: title)
            metadata.append(titleItem)
        }

        if let subtitle {
            let sutitleItem = AVMutableMetadataItem()
            sutitleItem.identifier = .iTunesMetadataTrackSubTitle
            sutitleItem.value = NSString(string: subtitle)
            metadata.append(sutitleItem)
        }

        if let description {
            let descriptionItem = AVMutableMetadataItem()
            descriptionItem.identifier = .commonIdentifierDescription
            descriptionItem.value = NSString(string: description)
            metadata.append(descriptionItem)
        }

        return metadata
    }

    func getMetadata() async -> (title: String, subtitle: String, description: String)? {
        do {
            let episodeData = try await api.sendApiRequest(GetEpisodeRequest(episodeId: episodeId))
            let showData = try await api.sendApiRequest(GetSeriesRequest(seriesId: episodeData.seriesId))
            let translation = episodeData.translations.first(where: { $0.id == translationId })

            var description = ""

            if let translation {
                description = "Переведено командой: \(translation.authorsSummary)"
            }

            return (
                title: episodeData.episodeFull,
                subtitle: showData.titles.romaji ?? showData.title,
                description: description
            )
        } catch {
            print("Cannot download metadata \(error)")
            return nil
        }
    }
}
