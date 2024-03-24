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
    static var getWebsiteBaseUrl: URL {
        URL(string: "https://anime365.ru")!
    }

    static var getApplicationId: String {
        Bundle.main.bundleIdentifier ?? "ichime"
    }

    static var getApplicationName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Ichime"
    }

    static var getPermittedScheduleBGTaskName: String {
        "dev.midorinome.ichime.background-tasks"
    }

    static var getApplicationVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.1"
    }

    static var getUserAgent: String {
        return "\(getApplicationName) (\(getApplicationVersion) / Contact: petr@flaks.xyz"
    }
}
