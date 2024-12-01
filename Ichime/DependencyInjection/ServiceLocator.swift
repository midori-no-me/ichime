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
  static var websiteBaseUrl: URL {
    UserDefaults.standard.url(forKey: "anime365-base-url") ?? URL(string: "https://anime365.ru")!
  }

  static var applicationId: String {
    guard let appId = Bundle.main.bundleIdentifier else {
      fatalError("Cannot get App Id")
    }
    return appId
  }

  static var applicationName: String {
    guard let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String else {
      fatalError("Cannot get App Name")
    }
    return appName
  }

  static var permittedScheduleBGTaskName: String {
    guard
      let tasks = Bundle.main.object(forInfoDictionaryKey: "BGTaskSchedulerPermittedIdentifiers")
        as? [String],
      let task = tasks.first
    else {
      fatalError("Cannot get bg task name")
    }

    return task
  }

  static var applicationVersion: String {
    guard
      let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
        as? String
    else {
      fatalError("Cannot get App Version")
    }
    return version
  }

  static let appGroup = "group.dev.midorinome.ichime.group"

  static var userAgent: String {
    return "\(applicationName) (\(applicationVersion) / Contact: petr@flaks.xyz"
  }

  static let topShellSchema = "ichime-top-shelf"

  static var shikimoriUserAgent: String {
    return "Ichime"
  }

  static var shikimoriBaseUrl: URL {
    return URL(string: "https://shikimori.one")!
  }
}
