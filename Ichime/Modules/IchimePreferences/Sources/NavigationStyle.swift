import Foundation

public enum NavigationStyle: String, CaseIterable, Identifiable, Sendable {
  case sideBar
  case tabBar

  public struct UserDefaultsKey {
    public static let STYLE = "navigationStyle"
  }

  public static let DEFAULT_STYLE: Self = .tabBar

  public var id: String {
    self.rawValue
  }

  public var name: String {
    switch self {
    case .sideBar:
      "Меню слева (beta)"
    case .tabBar:
      "Вкладки сверху"
    }
  }
}
