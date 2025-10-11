@preconcurrency import DITranquillity
import Foundation
import JikanApiClient
import OSLog
import ShikimoriApiClient
import SwiftData

final class ApplicationDependency: DIFramework {
  static let container: DIContainer = {
    let container = DIContainer()
    container.append(framework: ApplicationDependency.self)
    return container
  }()

  static func load(container: DIContainer) {
    container
      .register {
        let urlSessionConfig = URLSessionConfiguration.default
        urlSessionConfig.httpCookieStorage = .sharedCookieStorage(forGroupContainerIdentifier: ServiceLocator.appGroup)
        urlSessionConfig.httpAdditionalHeaders?["User-Agent"] = ServiceLocator.userAgent

        return URLSession(configuration: urlSessionConfig)
      }

    container.register {
      ShikimoriApiClient.ApiClient(
        baseUrl: ServiceLocator.shikimoriBaseUrl,
        urlSession: $0,
        logger: Logger(subsystem: ServiceLocator.applicationId, category: "ShikimoriApiClient")
      )
    }

    container.register {
      JikanApiClient.ApiClient(
        baseUrl: ServiceLocator.jikanBaseUrl,
        urlSession: $0,
        logger: Logger(subsystem: ServiceLocator.applicationId, category: "JikanApiClient")
      )
    }

    container.register {
      ShowService(anime365KitFactory: $0, shikimoriApiClient: $1, jikanApiClient: $2)
    }

    container.register {
      EpisodeService(anime365KitFactory: $0, jikanApiClient: $1)
    }

    container.register {
      CurrentlyWatchingService(anime365KitFactory: $0)
    }

    container.register {
      SubtitlesProxyUrlGenerator(
        anime365BaseUrl: ServiceLocator.websiteBaseUrl
      )
    }

    container.register {
      ShowReleaseSchedule(shikimoriApiClient: $0)
    }

    container.register {
      MomentService(anime365KitFactory: $0)
    }

    container.register {
      ShowSearchService(shikimoriApiClient: $0)
    }

    container.register {
      Anime365KitFactory(
        anime365BaseURL: $0,
        logger: Logger(subsystem: ServiceLocator.applicationId, category: "Anime365Kit"),
        urlSession: $1
      )
    }

    container.register {
      AuthenticationManager(
        anime365KitFactory: $0,
        currentUserInfo: $1,
        animeListEntriesCount: $2,
        urlSession: $3
      )
    }

    container.register {
      Anime365BaseURL()
    }

    container.register {
      CurrentUserInfo()
    }

    container.register {
      AnimeListEntriesCount()
    }

    container.register {
      AnimeListService(
        anime365KitFactory: $0
      )
    }

    if !container.makeGraph().checkIsValid() {
      fatalError("Граф зависимостей не валиден")
    }
  }
}
