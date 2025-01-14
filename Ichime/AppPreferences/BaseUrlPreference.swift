//
//  CommonPreferences.swift
//  ichime
//
//  Created by p.flaks on 28.01.2024.
//

import Foundation
import SwiftUI

class BaseUrlPreference: ObservableObject {
  private let userDefaults: UserDefaults
  private let baseURLKey = "anime365-base-url"
  private let defaultURL = URL(string: "https://smotret-anime.org")!

  init() {
    guard let userDefaults = UserDefaults(suiteName: ServiceLocator.appGroup) else {
      fatalError("Не удалось получить UserDefaults для appGroup: \(ServiceLocator.appGroup)")
    }
    self.userDefaults = userDefaults
  }

  var url: URL {
    get {
      if let urlString = userDefaults.string(forKey: baseURLKey),
        let url = URL(string: urlString)
      {
        return url
      }
      userDefaults.set(defaultURL.absoluteString, forKey: baseURLKey)
      return defaultURL
    }
    set {
      userDefaults.set(newValue.absoluteString, forKey: baseURLKey)
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        exit(0)
      }
    }
  }

  static let allPossibleWebsiteBaseDomains = [
    URL(string: "https://smotret-anime.org")!,
    URL(string: "https://anime365.ru")!,
    URL(string: "https://anime-365.ru")!,
    URL(string: "https://smotret-anime.com")!,
    URL(string: "https://smotret-anime.online")!,
    URL(string: "https://smotret-anime.net")!,
  ]
}
