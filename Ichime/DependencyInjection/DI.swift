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

class ApplicationDependency: DIFramework {
    static let container: DIContainer = {
        let container = DIContainer()
        container.append(framework: ApplicationDependency.self)
        return container
    }()

    static func load(container: DIContainer) {
        #if os(tvOS)
            container
                .register { HTTPCookieStorage.sharedCookieStorage(forGroupContainerIdentifier: ServiceLocator.appGroup)
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

        container.register { Anime365ApiClient(
            baseURL: ServiceLocator.websiteBaseUrl,
            userAgent: ServiceLocator.userAgent,
            cookieStorage: $0
        ) }

        container.register { Anime365Client(apiClient: $0) }

        container.register { ShikimoriApiClient(
          baseUrl: ServiceLocator.shikimoriBaseUrl,
          userAgent: ServiceLocator.shikimoriUserAgent
        ) }

        if !container.makeGraph().checkIsValid() {
            fatalError("Граф зависимостей не валиден")
        }
    }
}
