import Foundation

public enum TranslationsOtherVisibility: String, CaseIterable, Identifiable, Sendable {
  case show
  case hide

  // MARK: Nested Types

  public struct UserDefaultsKey {
    public static let VISIBILITY = "translations_other_visibility"
  }

  // MARK: Static Properties

  public static let DEFAULT_VISIBILITY: Self = .show

  // MARK: Computed Properties

  public var id: String {
    self.rawValue
  }

  public var name: String {
    switch self {
    case .show:
      "Показывать"
    case .hide:
      "Скрыть"
    }
  }

  // MARK: Static Functions

  public static func get() -> Self {
    let value = UserDefaults.standard.string(forKey: Self.UserDefaultsKey.VISIBILITY)

    guard let value else {
      return Self.DEFAULT_VISIBILITY
    }

    return .init(rawValue: value) ?? Self.DEFAULT_VISIBILITY
  }
}
