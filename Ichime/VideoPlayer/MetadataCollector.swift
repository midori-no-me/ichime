import AVFoundation
import Anime365ApiClient
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
  let image: Data?
  let year: Int?
}

struct MetadataCollector {
  let api: Anime365ApiClient
  let episodeId: Int
  let translationId: Int

  init(
    episodeId: Int,
    translationId: Int,
    api: Anime365ApiClient = ApplicationDependency.container.resolve()
  ) {
    self.episodeId = episodeId
    self.translationId = translationId
    self.api = api
  }

  static func createMetadataItems(for metadata: MetadataPlayer) -> [AVMetadataItem] {
    let mapping: [AVMetadataIdentifier: Any?] = [
      .commonIdentifierTitle: metadata.title,
      .iTunesMetadataTrackSubTitle: metadata.subtitle,
      .commonIdentifierArtwork: metadata.image != nil
        ? (UIImage(data: metadata.image!)?.pngData() as Any) : nil,
      .commonIdentifierDescription: metadata.description,
      .quickTimeMetadataGenre: metadata.genre,
      .identifier3GPUserDataRecordingYear: metadata.year,
    ]

    return mapping.compactMap { createMetadataItem(for: $0, value: $1) }
  }

  private static func createMetadataItem(
    for identifier: AVMetadataIdentifier,
    value: Any?
  ) -> AVMetadataItem? {
    guard let value else { return nil }
    let item = AVMutableMetadataItem()
    item.identifier = identifier
    item.value = value as? NSCopying & NSObjectProtocol
    // Specify "und" to indicate an undefined language.
    item.extendedLanguageTag = "und"
    return item.copy() as! AVMetadataItem
  }

  private func getRating(malScore: String, worldartScore: String) -> String? {
    if malScore != "-1" {
      return "MAL: \(malScore)"
    }

    if worldartScore != "-1" {
      return "WorldART: \(worldartScore)"
    }

    return nil
  }

  func getMetadata() async -> MetadataPlayer? {
    do {
      let episodeData = try await api.sendApiRequest(GetEpisodeRequest(episodeId: episodeId))
      let showData = try await api.sendApiRequest(GetSeriesRequest(seriesId: episodeData.seriesId))
      let translation = episodeData.translations.first(where: { $0.id == translationId })

      var description = ""

      if let translation {
        if let desc = showData.descriptions?.first {
          description = "\(desc.value)\n\n© \(desc.source)"
        }
        description += "\n\nПереведено командой: \(translation.authorsSummary)"
      }

      var image: Data?

      if let imageURL = URL(string: showData.posterUrl) {
        do {
          let (data, _) = try await URLSession.shared.data(from: imageURL)
          image = data
        }
        catch {
          print("cannot download image for meta \(error)")
        }
      }

      return .init(
        title: episodeData.episodeFull,
        subtitle: showData.titles.romaji ?? showData.title,
        description: description,
        genre: showData.genres?.map { $0.title }.joined(separator: ", "),
        image: image,
        year: showData.year
      )
    }
    catch {
      print("Cannot download metadata \(error)")
      return nil
    }
  }
}
