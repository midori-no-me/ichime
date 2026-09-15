import Anime365Kit
import Foundation

public struct EpisodeInfo: Identifiable, Hashable {
  // MARK: Properties

  public let anime365ID: Int
  public let episodeNumber: Int?
  public let anime365Title: String
  public let uploadedAt: Date

  // MARK: Computed Properties

  public var id: Int {
    self.anime365ID
  }

  // MARK: Static Functions

  public static func createValid(anime365EpisodePreview: Anime365Kit.EpisodeProtocol) -> Self? {
    if anime365EpisodePreview.isActive != 1 || anime365EpisodePreview.isFirstUploaded != 1 {
      return nil
    }

    if Anime365Kit.ApiDateDecoder.isEmptyDate(anime365EpisodePreview.firstUploadedDateTime) {
      return nil
    }

    let anime365EpisodeNumber = Int(exactly: anime365EpisodePreview.episodeInt)

    let isTrailer = anime365EpisodePreview.episodeType == "preview"

    let isNonStandardEpisodeUploadedToAnime365 = anime365EpisodeNumber == nil || isTrailer

    return Self(
      anime365ID: anime365EpisodePreview.id,
      episodeNumber: isNonStandardEpisodeUploadedToAnime365 ? nil : anime365EpisodeNumber,
      anime365Title: anime365EpisodePreview.episodeFull,
      uploadedAt: anime365EpisodePreview.firstUploadedDateTime
    )
  }
}
