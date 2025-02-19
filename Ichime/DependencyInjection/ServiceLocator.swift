import Foundation

enum ServiceLocator {
  static let appGroup = "group.dev.midorinome.ichime.group"

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
    "\(applicationName) (\(applicationVersion) / Contact: petr@flaks.xyz"
  }

  static var shikimoriUserAgent: String {
    "Ichime"
  }

  static var shikimoriBaseUrl: URL {
    URL(string: "https://shikimori.one")!
  }

  static var jikanUserAgent: String {
    "Ichime"
  }

  static var jikanBaseUrl: URL {
    URL(string: "https://api.jikan.moe/v4")!
  }
}
