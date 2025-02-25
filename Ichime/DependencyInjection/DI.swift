import Anime365ApiClient
import DITranquillity
import Foundation
import JikanApiClient
import OSLog
import ScraperAPI
import ShikimoriApiClient
import SwiftData

class ApplicationDependency: DIFramework {
  static let container: DIContainer = {
    let container = DIContainer()
    container.append(framework: ApplicationDependency.self)
    return container
  }()

  static func load(container: DIContainer) {
    container.register {
      let schema = Schema([
        UserAnimeListModel.self
      ])

      let modelConfiguration = ModelConfiguration(
        schema: schema,
        groupContainer: .identifier(ServiceLocator.appGroup)
      )

      do {
        return try ModelContainer(for: schema, configurations: [modelConfiguration])
      }
      catch {
        fatalError("Could not create ModelContainer: \(error)")
      }
    }.lifetime(.single)

    container
      .register {
        HTTPCookieStorage.sharedCookieStorage(forGroupContainerIdentifier: ServiceLocator.appGroup)
      }

    container
      .register {
        ScraperAPI.Session(
          cookieStorage: $0,
          baseURL: ServiceLocator.websiteBaseUrl
        )
      }

    container
      .register {
        ScraperAPI.APIClient(
          baseURL: ServiceLocator.websiteBaseUrl,
          userAgent: ServiceLocator.userAgent,
          session: $0
        )
      }

    container.register { UserManager(client: $0) }
      .lifetime(.single)

    container.register {
      Anime365ApiClient.ApiClient(
        baseURL: ServiceLocator.websiteBaseUrl,
        userAgent: ServiceLocator.userAgent,
        cookieStorage: $0,
        logger: Logger(subsystem: ServiceLocator.applicationId, category: "Anime365ApiClient")
      )
    }

    container.register {
      UserAnimeListCache(apiClient: $0, userManager: $1, modelContainer: $2)
    }

    container.register { Anime365Client(apiClient: $0) }

    container.register {
      ShikimoriApiClient.ApiClient(
        baseUrl: ServiceLocator.shikimoriBaseUrl,
        userAgent: ServiceLocator.shikimoriUserAgent,
        logger: Logger(subsystem: ServiceLocator.applicationId, category: "ShikimoriApiClient")
      )
    }

    container.register {
      JikanApiClient.ApiClient(
        baseUrl: ServiceLocator.jikanBaseUrl,
        userAgent: ServiceLocator.jikanUserAgent,
        logger: Logger(subsystem: ServiceLocator.applicationId, category: "JikanApiClient")
      )
    }

    container.register {
      ShowService(anime365ApiClient: $0, shikimoriApiClient: $1, jikanApiClient: $2, momentsService: $3)
    }

    container.register {
      EpisodeService(anime365ApiClient: $0, jikanApiClient: $1)
    }

    container.register {
      CurrentlyWatchingService(scraperApi: $0)
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
      HomeService(showService: $0, momentService: $1)
    }

    container.register {
      MomentService(scraperApi: $0)
    }

    if !container.makeGraph().checkIsValid() {
      fatalError("Граф зависимостей не валиден")
    }
  }
}
