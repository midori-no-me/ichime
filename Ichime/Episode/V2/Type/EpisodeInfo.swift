import Anime365ApiClient
import Foundation
import JikanApiClient

struct EpisodeInfo {
  let anime365Id: Int
  let episodeNumber: Int?
  let anime365Title: String
  let officialTitle: String?
  let officiallyAiredAt: Date?
  let myAnimeListScore: Float?
  let isFiller: Bool
  let isRecap: Bool
  let uploadedAt: Date
  let synopsis: String?
  let duration: Duration?

  static func createValid(
    anime365EpisodePreview: Anime365ApiClient.Episode,
    jikanEpisode: JikanApiClient.Episode?,
    totalEpisodes: Int?
  ) -> Self? {
    if anime365EpisodePreview.isActive != 1 || anime365EpisodePreview.isFirstUploaded != 1 {
      return nil
    }

    if Anime365ApiClient.ApiDateDecoder.isEmptyDate(anime365EpisodePreview.firstUploadedDateTime) {
      return nil
    }

    let anime365EpisodeNumber = Int(anime365EpisodePreview.episodeInt)

    // Если номер эпизода больше, чем общее количество эпизодов, заявленных в тайтле, то считаем такой эпизод не валидным
    if let anime365EpisodeNumber, let totalEpisodes, anime365EpisodeNumber > totalEpisodes {
      return nil
    }

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

      synopsis = jikanEpisode?.synopsis

      let durationInt = jikanEpisode?.duration

      if let durationInt {
        duration = .seconds(durationInt)
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
      uploadedAt: anime365EpisodePreview.firstUploadedDateTime,
      synopsis: synopsis,
      duration: duration
    )
  }
}
