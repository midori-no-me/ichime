import Anime365ApiClient
import Foundation
import JikanApiClient
import OSLog
import ScraperAPI
import ShikimoriApiClient

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

  static var shikimoriApiClient: ShikimoriApiClient.ApiClient {
    .init(
      baseUrl: Self.shikimoriBaseUrl,
      userAgent: Self.shikimoriUserAgent,
      logger: Logger(subsystem: Self.applicationId, category: "ShikimoriApiClient")
    )
  }

  static var jikanApiClient: JikanApiClient.ApiClient {
    .init(
      baseUrl: Self.jikanBaseUrl,
      userAgent: Self.jikanUserAgent,
      logger: Logger(subsystem: Self.applicationId, category: "JikanApiClient")
    )
  }

  static var showServiceAnime365: ShowService {
    .init(
      anime365ApiClient: Self.anime365ApiClient,
      shikimoriApiClient: Self.shikimoriApiClient,
      jikanApiClient: Self.jikanApiClient,
      scraperApi: Self.scraperApiClient
    )
  }

  static var showServiceHentai365: ShowService {
    .init(
      anime365ApiClient: Self.hentai365ApiClient,
      shikimoriApiClient: Self.shikimoriApiClient,
      jikanApiClient: Self.jikanApiClient,
      scraperApi: Self.scraperApiClient
    )
  }

  static var cookieStorage: HTTPCookieStorage {
    HTTPCookieStorage.sharedCookieStorage(forGroupContainerIdentifier: Self.appGroup)
  }

  static var hentai365ApiClient: Anime365ApiClient.ApiClient {
    .init(
      baseURL: URL(string: "https://hentai365.ru")!,
      userAgent: Self.userAgent,
      cookieStorage: Self.cookieStorage,
      logger: Logger(subsystem: Self.applicationId, category: "Hentai365ApiClient")
    )
  }

  static var anime365ApiClient: Anime365ApiClient.ApiClient {
    .init(
      baseURL: Self.websiteBaseUrl,
      userAgent: Self.userAgent,
      cookieStorage: Self.cookieStorage,
      logger: Logger(subsystem: Self.applicationId, category: "Anime365ApiClient")
    )
  }

  static var scraperApiSession: ScraperAPI.Session {
    .init(
      cookieStorage: Self.cookieStorage,
      baseURL: Self.websiteBaseUrl
    )
  }

  static var scraperApiClient: ScraperAPI.APIClient {
    .init(
      baseURL: Self.websiteBaseUrl,
      userAgent: Self.userAgent,
      session: Self.scraperApiSession
    )
  }

  static var hentai365HomeService: Hentai365HomeService {
    .init(
      showService: Self.showServiceHentai365
    )
  }

  static var anime365HomeService: Anime365HomeService {
    .init(
      showService: Self.showServiceAnime365
    )
  }
}
