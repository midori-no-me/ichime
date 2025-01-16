import Anime365ApiClient
import DITranquillity
import Foundation
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
        UserAnimeListModel.self,
        DbAnime.self,
        DbGenre.self,
        DbStudio.self,
      ])
      let storeURL = URL.documentsDirectory.appending(path: "offline.sqlite")
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
      .register { VideoPlayerHolder() }
      .lifetime(.single)

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
      Anime365ApiClient(
        baseURL: ServiceLocator.websiteBaseUrl,
        userAgent: ServiceLocator.userAgent,
        cookieStorage: $0
      )
    }

    container.register {
      UserAnimeListCache(apiClient: $0, userManager: $1, modelContainer: $2)
    }

    container.register {
      DbService(modelContainer: $0)
    }

    container.register { Anime365Client(apiClient: $0) }

    container.register {
      ShikimoriApiClient(
        baseUrl: ServiceLocator.shikimoriBaseUrl,
        userAgent: ServiceLocator.shikimoriUserAgent
      )
    }

    if !container.makeGraph().checkIsValid() {
      fatalError("Граф зависимостей не валиден")
    }
  }
}
