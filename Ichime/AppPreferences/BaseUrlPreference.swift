import Foundation
import OrderedCollections
import SwiftUI

class BaseUrlPreference: ObservableObject {
  static let allPossibleWebsiteBaseDomains: OrderedSet = .init(
    [
      URL(string: "https://anime365.ru")!,
      URL(string: "https://anime-365.ru")!,
      URL(string: "https://smotret-anime.org")!,
      URL(string: "https://smotret-anime.com")!,
      URL(string: "https://smotret-anime.online")!,
      URL(string: "https://smotret-anime.net")!,
      URL(string: "https://smotret-anime.ru")!,
      URL(string: "https://smotretanime.ru")!,
    ].sorted(by: { $0.absoluteString < $1.absoluteString })
  )

  private let userDefaults: UserDefaults
  private let baseURLKey = "anime365-base-url"
  private let defaultURL: URL = .init(string: "https://smotret-anime.org")!

  var url: URL {
    get {
      if let urlString = userDefaults.string(forKey: baseURLKey),
        let url = URL(string: urlString)
      {
        return url
      }
      self.userDefaults.set(self.defaultURL.absoluteString, forKey: self.baseURLKey)
      return self.defaultURL
    }
    set {
      self.userDefaults.set(newValue.absoluteString, forKey: self.baseURLKey)
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        exit(0)
      }
    }
  }

  init() {
    guard let userDefaults = UserDefaults(suiteName: ServiceLocator.appGroup) else {
      fatalError("Не удалось получить UserDefaults для appGroup: \(ServiceLocator.appGroup)")
    }
    self.userDefaults = userDefaults
  }
}
