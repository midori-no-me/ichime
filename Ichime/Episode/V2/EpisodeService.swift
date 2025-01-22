import Anime365ApiClient
import JikanApiClient

struct EpisodeService {
  private let anime365ApiClient: Anime365ApiClient
  private let jikanApiClient: JikanApiClient

  init(
    anime365ApiClient: Anime365ApiClient,
    jikanApiClient: JikanApiClient
  ) {
    self.anime365ApiClient = anime365ApiClient
    self.jikanApiClient = jikanApiClient
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

    var jikanEpisodes: [Episode] = []

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
