import Foundation
import OrderedCollections

enum NavigationStyle: String, CaseIterable, Identifiable {
  case sideBar
  case tabBar

  struct UserDefaultsKey {
    static let STYLE = "navigationStyle"
  }

  static let DEFAULT_STYLE: Self = .tabBar

  var id: String {
    self.rawValue
  }

  var name: String {
    switch self {
    case .sideBar:
      "Меню слева (beta)"
    case .tabBar:
      "Вкладки сверху"
    }
  }
}
