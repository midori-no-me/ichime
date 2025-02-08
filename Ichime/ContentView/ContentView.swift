import SwiftUI

private enum NavigationStyle: String {
  case sideBar
  case tabBar
}

struct ContentView: View {
  private var userManager: UserManager = ApplicationDependency.container.resolve()

  @AppStorage("navigationStyle") private var navigationStyle: NavigationStyle = .tabBar

  var body: some View {
    switch self.userManager.state {
    case .idle:
      Color.clear
    case .loading:
      ProgressView()
        .focusable()

    case .isAuth:
      switch self.navigationStyle {
      case .tabBar:
        ContentViewWithTabBar()
          .markEpisodeAsWatchedAlert()
      case .sideBar:
        ContentViewWithSideBar()
          .markEpisodeAsWatchedAlert()
      }
    case .isAnonym:
      NavigationStack {
        OnboardingView()
      }
    }
  }
}

@ViewBuilder
func viewEpisodes(show: WatchCardModel) -> some View {
  EpisodeTranslationListView(episodeId: show.data.episode)
}
