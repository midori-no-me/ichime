import Foundation
import OrderedCollections

actor Anime365BaseURL {
  struct UserDefaultsKey {
    static let BASE_URL = "anime365_base_url"
  }

  static let DEFAULT_BASE_URL: URL = .init(string: "https://smotret-anime.org")!
  static let ALL_KNOWN_ANIME_365_BASE_URLS: OrderedSet<URL> = .init(
    [
      URL(string: "https://anime365.ru")!,
      URL(string: "https://anime-365.ru")!,
      URL(string: "https://smotret-anime.app")!,
      URL(string: "https://smotret-anime.org")!,
      URL(string: "https://smotret-anime.com")!,
      URL(string: "https://smotret-anime.online")!,
      URL(string: "https://smotret-anime.net")!,
      URL(string: "https://smotret-anime.ru")!,
      URL(string: "https://smotretanime.ru")!,
    ].sorted(by: { $0.absoluteString < $1.absoluteString })
  )

  private let userDefaults: UserDefaults

  init() {
    self.userDefaults = Self.getUserDefaults()
  }

  static func getUserDefaults() -> UserDefaults {
    guard let userDefaults = UserDefaults(suiteName: ServiceLocator.appGroup) else {
      fatalError("Error creating UserDefaults for App Group: \(ServiceLocator.appGroup)")
    }

    return userDefaults
  }

  func get() -> URL {
    self.userDefaults.url(forKey: Self.UserDefaultsKey.BASE_URL) ?? Self.DEFAULT_BASE_URL
  }
}
