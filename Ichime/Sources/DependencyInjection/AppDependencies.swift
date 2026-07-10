import Foundation
import IchimeAnime365
import IchimeCalendar
import IchimeCore
import IchimeCurrentlyWatching
import IchimeEpisode
import IchimeMoment
import IchimeMyLists
import IchimeProfile
import IchimeShow
import IchimeVideoPlayer
import JikanApiClient
import OSLog
import ShikimoriApiClient
import SwiftUI

struct AppDependencies: Sendable {
  // MARK: Static Properties

  static let live: Self = {
    let urlSession = AppEnvironment.urlSession

    let anime365BaseURL = Anime365BaseURL()
    let animeListEntriesCount = AnimeListEntriesCount()

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

    let shikimoriGraphQLClient = ShikimoriApiClient.GraphQLClient(
      baseURL: AppEnvironment.shikimoriBaseURL,
      urlSession: urlSession,
      logger: Logger(subsystem: AppEnvironment.applicationID, category: "ShikimoriGraphQLClient")
    )

    let jikanApiClient = JikanApiClient.ApiClient(
      baseURL: AppEnvironment.jikanBaseURL,
      urlSession: urlSession,
      logger: Logger(subsystem: AppEnvironment.applicationID, category: "JikanApiClient")
    )

    let showService = ShowService(
      anime365KitFactory: anime365KitFactory,
      shikimoriApiClient: shikimoriApiClient,
      shikimoriGraphQLClient: shikimoriGraphQLClient,
      jikanApiClient: jikanApiClient
    )

    let episodeService = EpisodeService(
      anime365KitFactory: anime365KitFactory,
      jikanApiClient: jikanApiClient
    )

    let currentlyWatchingService = CurrentlyWatchingService(
      anime365KitFactory: anime365KitFactory
    )

    let subtitlesProxyURLGenerator = SubtitlesProxyURLGenerator(
      anime365BaseURL: AppEnvironment.websiteBaseURL
    )

    let showReleaseSchedule = ShowReleaseSchedule(
      shikimoriApiClient: shikimoriApiClient,
      anime365BaseURL: anime365BaseURL
    )

    let momentService = MomentService(
      anime365KitFactory: anime365KitFactory
    )

    let showSearchService = ShowSearchService(
      shikimoriApiClient: shikimoriApiClient
    )

    let profilePageService = ProfilePageService(
      anime365KitFactory: anime365KitFactory
    )

    let authenticationManager = AuthenticationManager(
      anime365KitFactory: anime365KitFactory,
      animeListEntriesCount: animeListEntriesCount,
      profilePageService: profilePageService,
      urlSession: urlSession
    )

    let animeListService = AnimeListService(
      anime365KitFactory: anime365KitFactory
    )

    return .init(
      anime365KitFactory: anime365KitFactory,
      showService: showService,
      episodeService: episodeService,
      currentlyWatchingService: currentlyWatchingService,
      subtitlesProxyURLGenerator: subtitlesProxyURLGenerator,
      showReleaseSchedule: showReleaseSchedule,
      momentService: momentService,
      showSearchService: showSearchService,
      authenticationManager: authenticationManager,
      profilePageService: profilePageService,
      animeListEntriesCount: animeListEntriesCount,
      animeListService: animeListService
    )
  }()

  // MARK: Properties

  let anime365KitFactory: Anime365KitFactory
  let showService: ShowService
  let episodeService: EpisodeService
  let currentlyWatchingService: CurrentlyWatchingService
  let subtitlesProxyURLGenerator: SubtitlesProxyURLGenerator
  let showReleaseSchedule: ShowReleaseSchedule
  let momentService: MomentService
  let showSearchService: ShowSearchService
  let authenticationManager: AuthenticationManager
  let profilePageService: ProfilePageService
  let animeListEntriesCount: AnimeListEntriesCount
  let animeListService: AnimeListService
}

private struct AppDependenciesEnvironmentKey: EnvironmentKey {
  static let defaultValue: AppDependencies = .live
}

extension EnvironmentValues {
  var dependencies: AppDependencies {
    get { self[AppDependenciesEnvironmentKey.self] }
    set { self[AppDependenciesEnvironmentKey.self] = newValue }
  }
}
