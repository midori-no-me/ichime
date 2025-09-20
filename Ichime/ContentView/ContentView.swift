import SwiftUI

struct ContentView: View {
  @AppStorage(NavigationStyle.UserDefaultsKey.STYLE) private var navigationStyle: NavigationStyle = .tabBar

  var body: some View {
    switch self.navigationStyle {
    case .tabBar:
      ContentViewWithTabBar()
        .markEpisodeAsWatchedAlert()
    case .sideBar:
      ContentViewWithSideBar()
        .markEpisodeAsWatchedAlert()
    }
  }
}
