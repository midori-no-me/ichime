import Anime365ApiClient
import ShikimoriApiClient

struct ShowService {
  private let anime365ApiClient: Anime365ApiClient
  private let shikimoriApiClient: ShikimoriApiClient

  init(
    anime365ApiClient: Anime365ApiClient,
    shikimoriApiClient: ShikimoriApiClient
  ) {
    self.anime365ApiClient = anime365ApiClient
    self.shikimoriApiClient = shikimoriApiClient
  }

  func getFullShow(showId: Int) async throws -> ShowFull {
    let anime365ApiResponse = try await anime365ApiClient.sendApiRequest(
      GetSeriesRequest(
        seriesId: showId
      )
    )

    let shikimoriApiResponse = try await shikimoriApiClient.getAnimeById(
      animeId: anime365ApiResponse.myAnimeListId
    )

    return ShowFull.create(
      anime365Series: anime365ApiResponse,
      shikimoriAnime: shikimoriApiResponse,
      shikimoriBaseUrl: self.shikimoriApiClient.baseUrl
    )
  }
}
