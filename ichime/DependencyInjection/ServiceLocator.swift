//
//  ServiceLocator.swift
//  ichime
//
//  Created by p.flaks on 21.01.2024.
//

import Anime365ApiClient
import Foundation
import ScraperAPI

enum ServiceLocator {
    static func getWebsiteBaseUrl() -> URL {
        return URL(string: "https://anime365.ru")!
    }

    static func getApplicationName() -> String {
        if let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String {
            return appName
        } else {
            return "ichime"
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
        return "\(getApplicationName()) (\(getApplicationVersion())) / Contact: petr@flaks.xyz"
    }
}
