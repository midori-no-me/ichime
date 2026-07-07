import Foundation

public enum ServiceLocator {
  private static let fallbackAppGroup = "group.dev.midorinome.ichime.group"

  public static var isInstalledViaAppdb: Bool {
    AppdbSupport.isInstalledViaAppdb
  }

  public static var appGroup: String? {
    if forceAppGroups {
      return fallbackAppGroup
    }

    return AppdbSupport.appGroupIdentifier
  }

  public static var userDefaults: UserDefaults {
    guard let appGroup else {
      return .standard
    }

    return UserDefaults(suiteName: appGroup) ?? .standard
  }

  public static var cookieStorage: HTTPCookieStorage {
    guard let appGroup else {
      return .shared
    }

    return .sharedCookieStorage(forGroupContainerIdentifier: appGroup)
  }

  public static var websiteBaseUrl: URL {
    if let url = userDefaults.string(forKey: "anime365-base-url") {
      return URL(string: url)!
    }

    userDefaults.set("https://smotret-anime.org", forKey: "anime365-base-url")

    return URL(string: "https://smotret-anime.org")!
  }

  public static var applicationId: String {
    guard let appId = Bundle.main.bundleIdentifier else {
      fatalError("Cannot get App Id")
    }
    return appId
  }

  public static var applicationName: String {
    guard let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String else {
      fatalError("Cannot get App Name")
    }
    return appName
  }

  public static var applicationVersion: String {
    guard
      let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
        as? String
    else {
      fatalError("Cannot get App Version")
    }
    return version
  }

  public static var userAgent: String {
    "\(applicationName) (\(applicationVersion)) / Contact: petr@flaks.xyz"
  }

  public static var shikimoriBaseUrl: URL {
    URL(string: "https://shikimori.io")!
  }

  public static var jikanBaseUrl: URL {
    URL(string: "https://api.jikan.moe/v4")!
  }

  private static var forceAppGroups: Bool {
    guard let value = Bundle.main.object(forInfoDictionaryKey: "ICHForceAppGroups") as? String else {
      return false
    }

    return ["1", "true", "yes"].contains(value.lowercased())
  }
}
