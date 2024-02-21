//
//  DI.swift
//  ani365
//
//  Created by Nikita Nafranets on 31.01.2024.
//

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
            }.lifetime(.objectGraph)

        container.register { ScraperClient(scraperClient: $0) }
            .lifetime(.objectGraph)

        if !container.makeGraph().checkIsValid() {
            fatalError("Граф зависимостей не валиден")
        }
    }
}
