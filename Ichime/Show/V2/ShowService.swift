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
    let anime365Series = try await anime365ApiClient.sendApiRequest(
      GetSeriesRequest(
        seriesId: showId
      )
    )

    async let shikimoriAnimeFuture = shikimoriApiClient.getAnimeById(
      animeId: anime365Series.myAnimeListId
    )

    async let shikimoriScreenshotsFuture = shikimoriApiClient.getAnimeScreenshotsById(
      animeId: anime365Series.myAnimeListId
    )

    let shikimoriAnime = try await shikimoriAnimeFuture
    let shikimoriScreenshots = (try? await shikimoriScreenshotsFuture) ?? []

    return ShowFull.create(
      anime365Series: anime365Series,
      shikimoriAnime: shikimoriAnime,
      shikimoriScreenshots: shikimoriScreenshots,
      shikimoriBaseUrl: self.shikimoriApiClient.baseUrl
    )
  }
}
