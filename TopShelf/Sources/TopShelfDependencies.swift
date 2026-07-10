import IchimeAnime365
import IchimeCalendar
import IchimeCore
import IchimeCurrentlyWatching
import OSLog
import ShikimoriApiClient

struct TopShelfDependencies: Sendable {
  // MARK: Static Properties

  static let live: Self = {
    let urlSession = AppEnvironment.urlSession

    let anime365BaseURL = Anime365BaseURL()

    let anime365KitFactory = Anime365KitFactory(
      anime365BaseURL: anime365BaseURL,
      logger: Logger(subsystem: AppEnvironment.applicationID, category: "Anime365Kit"),
      urlSession: urlSession
    )

    let shikimoriApiClient = ShikimoriApiClient.ApiClient(
      baseURL: AppEnvironment.shikimoriBaseURL,
      urlSession: urlSession,
      logger: Logger(subsystem: AppEnvironment.applicationID, category: "ShikimoriApiClient")
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

  // MARK: Properties

  let showReleaseSchedule: ShowReleaseSchedule
  let currentlyWatchingService: CurrentlyWatchingService
}
