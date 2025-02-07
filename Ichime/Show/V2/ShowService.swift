import Anime365ApiClient
import JikanApiClient
import ScraperAPI
import ShikimoriApiClient

struct ShowService {
  private let anime365ApiClient: Anime365ApiClient.ApiClient
  private let shikimoriApiClient: ShikimoriApiClient.ApiClient
  private let jikanApiClient: JikanApiClient.ApiClient
  private let scraperApi: ScraperAPI.APIClient

  init(
    anime365ApiClient: Anime365ApiClient.ApiClient,
    shikimoriApiClient: ShikimoriApiClient.ApiClient,
    jikanApiClient: JikanApiClient.ApiClient,
    scraperApi: ScraperAPI.APIClient
  ) {
    self.anime365ApiClient = anime365ApiClient
    self.shikimoriApiClient = shikimoriApiClient
    self.jikanApiClient = jikanApiClient
    self.scraperApi = scraperApi
  }

  func getFullShow(showId: Int) async throws -> ShowFull {
    let anime365Series = try await anime365ApiClient.getSeries(
      seriesId: showId
    )

    async let anime365MomentsFuture = try await self.scraperApi.sendAPIRequest(
      ScraperAPI.Request.GetMomentsByShow(showId: showId, page: 0)
    )

    async let shikimoriAnimeFuture = self.shikimoriApiClient.getAnimeById(
      animeId: anime365Series.myAnimeListId
    )

    async let shikimoriScreenshotsFuture = self.shikimoriApiClient.getAnimeScreenshotsById(
      animeId: anime365Series.myAnimeListId
    )

    async let jikanCharactersFuture = self.jikanApiClient.getAnimeCharacters(
      id: anime365Series.myAnimeListId
    )

    async let jikanStaffMembersFuture = self.jikanApiClient.getAnimeStaff(
      id: anime365Series.myAnimeListId
    )

    let anime365Moments = (try? await anime365MomentsFuture) ?? []
    let shikimoriAnime = try await shikimoriAnimeFuture
    let shikimoriScreenshots = (try? await shikimoriScreenshotsFuture) ?? []
    let jikanCharacters = (try? await jikanCharactersFuture) ?? []
    let jikanStaffMembers = (try? await jikanStaffMembersFuture) ?? []

    return ShowFull.create(
      anime365Series: anime365Series,
      shikimoriAnime: shikimoriAnime,
      shikimoriScreenshots: shikimoriScreenshots,
      shikimoriBaseUrl: self.shikimoriApiClient.baseUrl,
      jikanCharacterRoles: jikanCharacters,
      jikanStaffMembers: jikanStaffMembers,
      anime365Moments: anime365Moments
    )
  }
}
