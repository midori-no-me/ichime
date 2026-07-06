import Foundation
import OrderedCollections

enum OngoingsVisibilityOna: String, CaseIterable, Identifiable {
  case show
  case hide

  struct UserDefaultsKey {
    static let VISIBILITY = "ongoings_visibility_ona"
  }

  static let DEFAULT_VISIBILITY: Self = .show

  var id: String {
    self.rawValue
  }

  var name: String {
    switch self {
    case .show:
      "Показывать"
    case .hide:
      "Скрыть"
    }
  }

  static func get() -> Self {
    let value = UserDefaults.standard.string(forKey: Self.UserDefaultsKey.VISIBILITY)

    guard let value else {
      return Self.DEFAULT_VISIBILITY
    }

    return .init(rawValue: value) ?? Self.DEFAULT_VISIBILITY
  }
}
