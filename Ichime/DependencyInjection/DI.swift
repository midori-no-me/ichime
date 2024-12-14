//
//  DI.swift
//  ichime
//
//  Created by Nikita Nafranets on 31.01.2024.
//

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
      let schema = Schema([ShowListStatusEntity.self])
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

    #if os(tvOS)
      container
        .register {
          HTTPCookieStorage.sharedCookieStorage(forGroupContainerIdentifier: ServiceLocator.appGroup)
        }
    #else
      container
        .register { HTTPCookieStorage.shared }
    #endif

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
      ShowListStatusModel(apiClient: $0, userManager: $1, modelContainer: $2)
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
