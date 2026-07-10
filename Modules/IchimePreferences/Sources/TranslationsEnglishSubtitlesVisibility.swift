import Foundation

public enum TranslationsEnglishSubtitlesVisibility: String, CaseIterable, Identifiable, Sendable {
  case show
  case hide

  public struct UserDefaultsKey {
    public static let VISIBILITY = "translations_english_subtitles_visibility"
  }

  public static let DEFAULT_VISIBILITY: Self = .show

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

  public static func get() -> Self {
    let value = UserDefaults.standard.string(forKey: Self.UserDefaultsKey.VISIBILITY)

    guard let value else {
      return Self.DEFAULT_VISIBILITY
    }

    return .init(rawValue: value) ?? Self.DEFAULT_VISIBILITY
  }
}
