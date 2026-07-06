import Foundation

enum ServiceLocator {
  private static let fallbackAppGroup = "group.dev.midorinome.ichime.group"

  static var isInstalledViaAppdb: Bool {
    AppdbSupport.isInstalledViaAppdb
  }

  static var appGroup: String? {
    if forceAppGroups {
      return fallbackAppGroup
    }

    return AppdbSupport.appGroupIdentifier
  }

  static var userDefaults: UserDefaults {
    guard let appGroup else {
      return .standard
    }

    return UserDefaults(suiteName: appGroup) ?? .standard
  }

  static var cookieStorage: HTTPCookieStorage {
    guard let appGroup else {
      return .shared
    }

    return .sharedCookieStorage(forGroupContainerIdentifier: appGroup)
  }

  static var websiteBaseUrl: URL {
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

  static var applicationVersion: String {
    guard
      let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
        as? String
    else {
      fatalError("Cannot get App Version")
    }
    return version
  }

  static var userAgent: String {
    "\(applicationName) (\(applicationVersion)) / Contact: petr@flaks.xyz"
  }

  static var shikimoriBaseUrl: URL {
    URL(string: "https://shikimori.io")!
  }

  static var jikanBaseUrl: URL {
    URL(string: "https://api.jikan.moe/v4")!
  }

  private static var forceAppGroups: Bool {
    guard let value = Bundle.main.object(forInfoDictionaryKey: "ICHForceAppGroups") as? String else {
      return false
    }

    return ["1", "true", "yes"].contains(value.lowercased())
  }
}
