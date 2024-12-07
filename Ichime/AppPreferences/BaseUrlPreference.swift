//
//  CommonPreferences.swift
//  ichime
//
//  Created by p.flaks on 28.01.2024.
//

import Foundation
import SwiftUI

class BaseUrlPreference: ObservableObject {
  @AppStorage("anime365-base-url") var url: URL = .init(string: "https://anime365.ru")! {
    didSet {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        exit(0)
      }
    }
  }

  static let allPossibleWebsiteBaseDomains = [
    URL(string: "https://anime365.ru")!,
    URL(string: "https://anime-365.ru")!,
    URL(string: "https://smotret-anime.com")!,
    URL(string: "https://smotret-anime.online")!,
    URL(string: "https://smotret-anime.net")!,
    URL(string: "https://smotret-anime.org/")!,
  ]
}
