import SwiftData
import SwiftUI

struct ContentViewWithSideBar: View {
  @AppStorage("ContentViewWithTabView.selectedTab") private var selectedTab: Tabs = .home
  @AppStorage("enable_hentai_365") private var enabledHentai365: Bool = false

  @State private var viewModel: UserAnimeListCache = ApplicationDependency.container.resolve()

  var body: some View {
    TabView(selection: self.$selectedTab) {
      Tab(self.enabledHentai365 ? "Anime 365" : "Главная", systemImage: "play.house", value: .home) {
        NavigationStackWithRouter {
          Anime365HomeView()
        }
      }

      if self.enabledHentai365 {
        Tab("Hentai 365", systemImage: "18.circle", value: .homeHentai) {
          NavigationStackWithRouter {
            Hentai365HomeView()
          }
        }
      }

      Tab("К просмотру", systemImage: "play.square.stack", value: .currentlyWatching) {
        NavigationStackWithRouter {
          CurrentlyWatchingView()
        }
      }

      Tab("Мой список", systemImage: "film.stack", value: .myLists) {
        NavigationStackWithRouter {
          MyListsSelectorView()
        }
      }

      Tab("Календарь", systemImage: "calendar", value: .calendar) {
        NavigationStackWithRouter {
          CalendarView()
        }
      }
      Tab("Профиль", systemImage: "person.circle", value: .profile) {
        NavigationStackWithRouter {
          ProfileView()
        }
      }

      Tab("Поиск", systemImage: "magnifyingglass", value: .search, role: .search) {
        NavigationStackWithRouter {
          SearchShowsView()
        }
      }
    }
    .tabViewStyle(.sidebarAdaptable)
    .task {
      await self.viewModel.cacheCategories()
    }
  }
}
