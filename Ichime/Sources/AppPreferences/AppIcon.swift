import Foundation
import OrderedCollections

enum AppIcon: CaseIterable {
  case anime365
  case hentai365
  case gawrGura

  var systemIdentifier: String? {
    switch self {
    case .anime365:
      nil
    case .hentai365:
      "App Icon - Hentai 365"
    case .gawrGura:
      "App Icon - Gawr Gura"
    }
  }

  var name: String {
    switch self {
    case .anime365:
      "Anime 365"
    case .hentai365:
      "Hentai 365"
    case .gawrGura:
      "Gawr Gura"
    }
  }

  static func create(fromSystemIdentifier systemIdentifier: String?) -> Self {
    for type in Self.allCases {
      if type.systemIdentifier == systemIdentifier {
        return type
      }
    }

    return .anime365
  }
}
