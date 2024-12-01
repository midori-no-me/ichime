//
//  ScraperAPI.Types.Episode.swift
//  ichime
//
//  Created by Nikita Nafranets on 05.04.2024.
//

import Foundation
import ScraperAPI

extension ScraperAPI.Types.Episode {
  public var displayName: String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.locale = Locale(identifier: "en_US")
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 1

    switch type {
    case .Movie:
      return "Фильм"
    case let .TV(episode):
      return String(localized: "\(formatter.string(for: episode)!) серия")
    case let .ONA(episode):
      return String(localized: "ONA \(formatter.string(for: episode)!) серия")
    case let .OVA(episode):
      return String(localized: "OVA \(formatter.string(for: episode)!) серия")
    }
  }
}
