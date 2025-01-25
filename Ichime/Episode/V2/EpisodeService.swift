import Anime365ApiClient
import JikanApiClient

struct EpisodeService {
  private let anime365ApiClient: Anime365ApiClient
  private let jikanApiClient: JikanApiClient.ApiClient

  init(
    anime365ApiClient: Anime365ApiClient,
    jikanApiClient: JikanApiClient.ApiClient
  ) {
    self.anime365ApiClient = anime365ApiClient
    self.jikanApiClient = jikanApiClient
  }

  /// Форматирует неизвестное количество эпизодов
  ///
  /// Полезно для ситуаций, когда общее количество эпизодов у сериала не известно.
  /// Принимает число (количество уже вышедших или уже просмотренных эпизодов) и возвращает количество вопросиков такой же длины.
  ///
  /// Примеры:
  ///
  /// - Если передать 5, то вернется  "??"
  /// - Если передать 55, то вернется  "??"
  /// - Если передать 555, то вернется  "???"
  /// - Если передать 5555, то вернется  "????"
  static func formatUnknownEpisodeCountBasedOnAlreadyAiredEpisodeCount(_ airedEpisodes: Int) -> String {
    let charactersLength = String(airedEpisodes).count

    return String(repeating: "?", count: max(2, charactersLength))
  }

  private static func mapAnime365EpisodesToJikanEpisodes(
    anime365EpisodePreviews: [Anime365ApiSeries.EpisodePreview],
    jikanEpisodes: [Episode]
  ) -> [EpisodeInfo] {
    var jikanEpisodeNumberToEpisode: [Int: Episode] = [:]

    for jikanEpisode in jikanEpisodes {
      jikanEpisodeNumberToEpisode[jikanEpisode.mal_id] = jikanEpisode
    }

    var episodeInfos: [EpisodeInfo] = []

    for anime365EpisodePreview in anime365EpisodePreviews {
      let anime365EpisodeNumber = Int(anime365EpisodePreview.episodeInt)

      var jikanEpisode: Episode? = nil

      if let anime365EpisodeNumber {
        jikanEpisode = jikanEpisodeNumberToEpisode[anime365EpisodeNumber]
      }

      let episodeInfo = EpisodeInfo.createValid(
        anime365EpisodePreview: anime365EpisodePreview,
        jikanEpisode: jikanEpisode
      )

      guard let episodeInfo else {
        continue
      }

      episodeInfos.append(episodeInfo)
    }

    return episodeInfos
  }

  func getEpisodeList(
    showId: Int
  ) async throws -> [EpisodeInfo] {
    let anime365Series = try await anime365ApiClient.sendApiRequest(
      GetSeriesRequest(
        seriesId: showId
      )
    )

    var jikanEpisodes: [JikanApiClient.Episode] = []

    // Jikan возвращает только 100 эпизодов за раз, поэтому пока не поддерживаем пагинацию
    if anime365Series.episodes?.count ?? 0 <= 100 {
      jikanEpisodes = (try? await self.jikanApiClient.getAnimeEpisodes(id: anime365Series.myAnimeListId)) ?? []
    }

    return Self.mapAnime365EpisodesToJikanEpisodes(
      anime365EpisodePreviews: anime365Series.episodes ?? [],
      jikanEpisodes: jikanEpisodes
    )
  }
}
