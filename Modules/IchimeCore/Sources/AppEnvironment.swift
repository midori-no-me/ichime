import Foundation

public enum AppEnvironment {
  // MARK: Static Properties

  public static let urlSession: URLSession = {
    let configuration = URLSessionConfiguration.default
    configuration.httpCookieStorage = cookieStorage
    configuration.httpAdditionalHeaders = [
      "User-Agent": userAgent
    ]

    return URLSession(configuration: configuration)
  }()

  private static let fallbackAppGroup = "group.dev.midorinome.ichime.group"

  // MARK: Static Computed Properties

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

  public static var websiteBaseURL: URL {
    if let url = userDefaults.string(forKey: "anime365-base-url") {
      return URL(string: url)!
    }

    userDefaults.set("https://smotret-anime.org", forKey: "anime365-base-url")

    return URL(string: "https://smotret-anime.org")!
  }

  public static var applicationID: String {
    guard let appID = Bundle.main.bundleIdentifier else {
      fatalError("Cannot get App Id")
    }
    return appID
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
    "\(applicationName)/\(applicationVersion)"
  }

  public static var shikimoriBaseURL: URL {
    URL(string: "https://shikimori.io")!
  }

  public static var jikanBaseURL: URL {
    URL(string: "https://api.jikan.moe/v4")!
  }

  private static var forceAppGroups: Bool {
    guard let value = Bundle.main.object(forInfoDictionaryKey: "ICHForceAppGroups") as? String else {
      return false
    }

    return ["1", "true", "yes"].contains(value.lowercased())
  }
}
