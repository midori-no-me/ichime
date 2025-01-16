import Anime365ApiClient
import Foundation
import ScraperAPI

enum ServiceLocator {
  static var websiteBaseUrl: URL {
    guard let userDefaults = UserDefaults(suiteName: appGroup) else {
      fatalError("Cannot get user defaults")
    }
    if let url = userDefaults.string(forKey: "anime365-base-url") {
      return URL(string: url)!
    }

    userDefaults.set("https://smotret-anime.org", forKey: "anime365-base-url")

    return URL(string: "https://smotret-anime.org")!
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
    "\(applicationName) (\(applicationVersion) / Contact: petr@flaks.xyz"
  }

  static let topShellSchema = "ichime-top-shelf"

  static var shikimoriUserAgent: String {
    "Ichime"
  }

  static var shikimoriBaseUrl: URL {
    URL(string: "https://shikimori.one")!
  }
}
