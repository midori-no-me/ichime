import IchimeAnime365
import IchimeCalendar
import IchimeCore
import IchimeCurrentlyWatching
import OSLog
import ShikimoriApiClient

struct TopShelfDependencies: Sendable {
  static let live: Self = {
    let urlSession = ServiceLocator.urlSession

    let anime365BaseURL = Anime365BaseURL()

    let anime365KitFactory = Anime365KitFactory(
      anime365BaseURL: anime365BaseURL,
      logger: Logger(subsystem: ServiceLocator.applicationId, category: "Anime365Kit"),
      urlSession: urlSession
    )

    let shikimoriApiClient = ShikimoriApiClient.ApiClient(
      baseUrl: ServiceLocator.shikimoriBaseUrl,
      urlSession: urlSession,
      logger: Logger(subsystem: ServiceLocator.applicationId, category: "ShikimoriApiClient")
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
