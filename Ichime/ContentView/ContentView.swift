import ScraperAPI
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
      case .sideBar:
        ContentViewWithSideBar()
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
  EpisodeTranslationsView(
    episodeId: show.data.episode,
    episodeTitle: show.data.title
  )
}

#Preview {
  ContentView()
}
