//
//  ServiceLocator.swift
//  ani365
//
//  Created by p.flaks on 21.01.2024.
//

import Foundation

enum ServiceLocator {
    static func getWebsiteBaseUrl() -> String {
        return "https://anime365.ru"
    }

    static func getApplicationName() -> String {
        if let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String {
            return appName
        } else {
            return "ani365"
        }
    }

    static func getApplicationVersion() -> String {
        if let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            return appVersion
        } else {
            return "0.0.1"
        }
    }

    static func getUserAgent() -> String {
        return "\(self.getApplicationName()) (\(self.getApplicationVersion())) / Contact: petr@flaks.xyz"
    }

    static func getAnime365Client() -> Anime365Client {
        return Anime365Client(
            apiClient: self.getAnime365ApiClient()
        )
    }

    static func getAnime365ApiClient() -> Anime365ApiClient {
        return Anime365ApiClient(
            baseURL: self.getWebsiteBaseUrl(),
            userAgent: self.getUserAgent()
        )
    }
}