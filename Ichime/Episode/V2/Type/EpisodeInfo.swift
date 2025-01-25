import Anime365ApiClient
import Foundation
import JikanApiClient

public struct EpisodeInfo {
  public let anime365Id: Int
  public let episodeNumber: Int?
  public let anime365Title: String
  public let officialTitle: String?
  public let officiallyAiredAt: Date?
  public let myAnimeListScore: Float?
  public let isFiller: Bool
  public let isRecap: Bool
  public let isTrailer: Bool
  public let uploadedAt: Date

  static func createValid(
    anime365EpisodePreview: Anime365ApiClient.Series.EpisodePreview,
    jikanEpisode: JikanApiClient.Episode?
  ) -> Self? {
    if anime365EpisodePreview.isActive != 1 || anime365EpisodePreview.isFirstUploaded != 1 {
      return nil
    }

    if Anime365ApiClient.ApiDateDecoder.isEmptyDate(anime365EpisodePreview.firstUploadedDateTime) {
      return nil
    }

    let anime365EpisodeNumber = Int(anime365EpisodePreview.episodeInt)

    let isTrailer = anime365EpisodePreview.episodeType == "preview"

    var title: String? = nil
    var officiallyAiredAt: Date? = nil
    var myAnimeListScore: Float? = nil
    var isFiller: Bool = false
    var isRecap: Bool = false

    // Если эпизод по каким-то признакам кажется не частью тайтла, а, допустим, трейлером или спешлом (с дробной серией),
    // то информацию из Jikan об этом эпизоде мы игнорируем
    let isNonStandardEpisodeUploadedToAnime365 = anime365EpisodeNumber == nil || isTrailer

    if !isNonStandardEpisodeUploadedToAnime365 {
      title = jikanEpisode?.title

      officiallyAiredAt = jikanEpisode?.aired

      if let scoreString = jikanEpisode?.score {
        myAnimeListScore = Float(scoreString)

        if myAnimeListScore == nil {
          return nil
        }
      }

      if let filler = jikanEpisode?.filler {
        isFiller = filler
      }

      if let recap = jikanEpisode?.recap {
        isRecap = recap
      }
    }

    return Self(
      anime365Id: anime365EpisodePreview.id,
      episodeNumber: isNonStandardEpisodeUploadedToAnime365 ? nil : anime365EpisodeNumber,
      anime365Title: anime365EpisodePreview.episodeFull,
      officialTitle: title,
      officiallyAiredAt: officiallyAiredAt,
      myAnimeListScore: myAnimeListScore,
      isFiller: isFiller,
      isRecap: isRecap,
      isTrailer: isTrailer,
      uploadedAt: anime365EpisodePreview.firstUploadedDateTime
    )
  }
}
