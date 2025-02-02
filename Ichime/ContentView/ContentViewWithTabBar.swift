import SwiftData
import SwiftUI

struct ContentViewWithTabBar: View {
  @AppStorage("ContentViewWithTabView.selectedTab") private var selectedTab: Tabs = .home
  @State private var route: Route?

  @State private var viewModel: UserAnimeListCache = ApplicationDependency.container.resolve()

  var body: some View {
    TabView(selection: self.$selectedTab) {
      Tab(value: .home) {
        NavigationStack {
          HomeView()
        }
      } label: {
        Text("Главная")
      }

      Tab(value: .currentlyWatching) {
        NavigationStack {
          CurrentlyWatchingView()
            .navigationDestination(
              for: WatchCardModel.self,
              destination: { viewEpisodes(show: $0) }
            )
        }
      } label: {
        Text("К просмотру")
      }

      Tab(value: .myLists) {
        NavigationStack {
          MyListsSelectorView()
        }
      } label: {
        Text("Мой список")
      }

      Tab(value: .notifications) {
        NavigationStack {
          NotificationCenterView()
            .navigationDestination(
              for: WatchCardModel.self,
              destination: { viewEpisodes(show: $0) }
            )
        }
      } label: {
        Text("Уведомления")
      }

      Tab(value: .profile) {
        NavigationStack {
          ProfileSheet()
        }
      } label: {
        Text("Профиль")
      }

      Tab(value: .search, role: .search) {
        NavigationStack {
          SearchShowsView()
        }
      } label: {
        Image(systemName: "magnifyingglass")
      }
    }
    .sheet(item: self.$route) { route in
      switch route.type {
      case .show:
        NavigationStack {
          ShowView(showId: route.id)
        }
      case .episode:
        EpisodeTranslationListView(episodeId: route.id)
      }
    }
    .tabViewStyle(.tabBarOnly)
    .task {
      await self.viewModel.cacheCategories()
    }
    .onOpenURL(perform: { url in
      guard url.scheme == ServiceLocator.topShellSchema,
        let components = URLComponents(
          url: url,
          resolvingAgainstBaseURL: true
        )
      else {
        return
      }

      guard let action = components.host,
        let rawId = components.queryItems?.first(where: { $0.name == "id" })?.value,
        let id = Int(rawId)
      else {
        return
      }

      let episodeTitle = components.queryItems?.first(where: { $0.name == "title" })?.value

      switch action {
      case URLActions.show.rawValue:
        print("its show \(id)")
        self.route = Route(id: id, type: .show)
      case URLActions.episode.rawValue:
        print("its episode \(id)")
        self.route = Route(id: id, type: .episode)
      default:
        print("idk")
      }
    })
  }
}
