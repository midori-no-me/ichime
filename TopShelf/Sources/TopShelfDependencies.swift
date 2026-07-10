import IchimeAnime365
import IchimeCalendar
import IchimeCore
import IchimeCurrentlyWatching
import OSLog
import ShikimoriApiClient

struct TopShelfDependencies: Sendable {
  static let live: Self = {
    let urlSession = AppEnvironment.urlSession

    let anime365BaseURL = Anime365BaseURL()

    let anime365KitFactory = Anime365KitFactory(
      anime365BaseURL: anime365BaseURL,
      logger: Logger(subsystem: AppEnvironment.applicationId, category: "Anime365Kit"),
      urlSession: urlSession
    )

    let shikimoriApiClient = ShikimoriApiClient.ApiClient(
      baseUrl: AppEnvironment.shikimoriBaseUrl,
      urlSession: urlSession,
      logger: Logger(subsystem: AppEnvironment.applicationId, category: "ShikimoriApiClient")
    )

    let showReleaseSchedule = ShowReleaseSchedule(
      shikimoriApiClient: shikimoriApiClient,
      anime365BaseURL: anime365BaseURL
    )

    let currentlyWatchingService = CurrentlyWatchingService(
      anime365KitFactory: anime365KitFactory
    )

    return .init(
      showReleaseSchedule: showReleaseSchedule,
      currentlyWatchingService: currentlyWatchingService
    )
  }()

  let showReleaseSchedule: ShowReleaseSchedule
  let currentlyWatchingService: CurrentlyWatchingService
}
