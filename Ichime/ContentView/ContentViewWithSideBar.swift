import SwiftData
import SwiftUI

struct ContentViewWithSideBar: View {
  @AppStorage("ContentViewWithTabView.selectedTab") private var selectedTab: Tabs = .home

  @State private var route: Route?

  @State private var viewModel: UserAnimeListCache = ApplicationDependency.container.resolve()

  var body: some View {
    TabView(selection: self.$selectedTab) {
      Tab("Главная", systemImage: "play.house", value: .home) {
        NavigationStack {
          HomeView()
        }
      }

      Tab("К просмотру", systemImage: "play.square.stack", value: .currentlyWatching) {
        NavigationStack {
          CurrentlyWatchingView()
            .navigationDestination(
              for: WatchCardModel.self,
              destination: { viewEpisodes(show: $0) }
            )
        }
      }

      Tab("Мой список", systemImage: "film.stack", value: .myLists) {
        NavigationStack {
          MyListsSelectorView()
        }
      }

      Tab(
        "Уведомления",
        systemImage: "bell",
        value: .notifications
      ) {
        NavigationStack {
          NotificationCenterView()
            .navigationDestination(
              for: WatchCardModel.self,
              destination: { viewEpisodes(show: $0) }
            )
        }
      }

      Tab("Календарь", systemImage: "calendar", value: .calendar) {
        NavigationStack {
          CalendarView()
        }
      }
      Tab("Профиль", systemImage: "person.circle", value: .profile) {
        NavigationStack {
          ProfileSheet()
        }
      }

      Tab("Поиск", systemImage: "magnifyingglass", value: .search, role: .search) {
        NavigationStack {
          SearchShowsView()
        }
      }
    }
    .tabViewStyle(.sidebarAdaptable)
    .task {
      await self.viewModel.cacheCategories()
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

enum URLActions: String {
  case show
  case episode
}

struct Route: Hashable, Identifiable {
  let id: Int
  let type: URLActions
}
