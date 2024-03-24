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
        guard let appId = Bundle.main.bundleIdentifier else {
            fatalError("Cannot get App Id")
        }
        return appId
    }

    static var getApplicationName: String {
        guard let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String else {
            fatalError("Cannot get App Name")
        }
        return appName
    }

    static var getPermittedScheduleBGTaskName: String {
        guard let tasks = Bundle.main.object(forInfoDictionaryKey: "BGTaskSchedulerPermittedIdentifiers") as? [String],
              let task = tasks.first
        else {
            fatalError("Cannot get bg task name")
        }

        return task
    }

    static var getApplicationVersion: String {
        guard let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            fatalError("Cannot get App Version")
        }
        return version
    }

    static var getUserAgent: String {
        return "\(getApplicationName) (\(getApplicationVersion) / Contact: petr@flaks.xyz"
    }
}
