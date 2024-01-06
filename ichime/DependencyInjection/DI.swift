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

class ApplicationDependency: DIFramework {
    static let container: DIContainer = {
        let container = DIContainer()
        container.append(framework: ApplicationDependency.self)
        return container
    }()

    static func load(container: DIContainer) {
        container
            .register {
                ScraperAPI.Session(cookieStorage: HTTPCookieStorage.shared, baseURL: ServiceLocator.getWebsiteBaseUrl())
            }

        container
            .register {
                ScraperAPI.APIClient(
                    baseURL: ServiceLocator.getWebsiteBaseUrl(),
                    userAgent: ServiceLocator.getUserAgent(),
                    session: $0
                )
            }

        container.register { UserManager(client: $0) }
            .lifetime(.single)

        container.register { Anime365ApiClient(
            baseURL: ServiceLocator.getWebsiteBaseUrl(),
            userAgent: ServiceLocator.getUserAgent()
        ) }

        container.register { Anime365Client(apiClient: $0) }

        if !container.makeGraph().checkIsValid() {
            fatalError("Граф зависимостей не валиден")
        }
    }
}
