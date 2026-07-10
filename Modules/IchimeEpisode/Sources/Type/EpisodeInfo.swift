import Anime365Kit
import Foundation
import JikanApiClient

public struct EpisodeInfo: Identifiable, Hashable {
  public let anime365ID: Int
  public let episodeNumber: Int?
  public let anime365Title: String
  public let officialTitle: String?
  public let officiallyAiredAt: Date?
  public let myAnimeListScore: Float?
  public let isFiller: Bool
  public let isRecap: Bool
  public let uploadedAt: Date
  public let synopsis: String?
  public let duration: Duration?

  public var id: Int {
    self.anime365ID
  }

  public static func createValid(
    anime365EpisodePreview: Anime365Kit.EpisodeProtocol,
    jikanEpisode: JikanApiClient.Episode?,
  ) -> Self? {
    if anime365EpisodePreview.isActive != 1 || anime365EpisodePreview.isFirstUploaded != 1 {
      return nil
    }

    if Anime365Kit.ApiDateDecoder.isEmptyDate(anime365EpisodePreview.firstUploadedDateTime) {
      return nil
    }

    let anime365EpisodeNumber = Int(anime365EpisodePreview.episodeInt)

    let isTrailer = anime365EpisodePreview.episodeType == "preview"

    var title: String? = nil
    var officiallyAiredAt: Date? = nil
    var myAnimeListScore: Float? = nil
    var isFiller: Bool = false
    var isRecap: Bool = false
    var synopsis: String? = nil
    var duration: Duration? = nil

    // Если эпизод по каким-то признакам кажется не частью тайтла, а, допустим, трейлером или спешлом (с дробной серией),
    // то информацию из Jikan об этом эпизоде мы игнорируем
    let isNonStandardEpisodeUploadedToAnime365 = anime365EpisodeNumber == nil || isTrailer

    if !isNonStandardEpisodeUploadedToAnime365 {
      if let officialTitle = jikanEpisode?.title, !officialTitle.isEmpty {
        title = officialTitle
      }

      officiallyAiredAt = jikanEpisode?.aired

      if let scoreString = jikanEpisode?.score {
        myAnimeListScore = Float(scoreString)
      }

      if let filler = jikanEpisode?.filler {
        isFiller = filler
      }

      if let recap = jikanEpisode?.recap {
        isRecap = recap
      }

      synopsis = jikanEpisode?.synopsis

      let durationInt = jikanEpisode?.duration

      if let durationInt, durationInt > 0 {
        duration = .seconds(durationInt)
      }
    }

    return Self(
      anime365ID: anime365EpisodePreview.id,
      episodeNumber: isNonStandardEpisodeUploadedToAnime365 ? nil : anime365EpisodeNumber,
      anime365Title: anime365EpisodePreview.episodeFull,
      officialTitle: title,
      officiallyAiredAt: officiallyAiredAt,
      myAnimeListScore: myAnimeListScore,
      isFiller: isFiller,
      isRecap: isRecap,
      uploadedAt: anime365EpisodePreview.firstUploadedDateTime,
      synopsis: synopsis,
      duration: duration
    )
  }
}
