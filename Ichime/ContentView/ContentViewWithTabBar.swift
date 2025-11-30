import SwiftData
import SwiftUI

struct ContentViewWithTabBar: View {
  @AppStorage("ContentViewWithTabView.selectedTab") private var selectedTab: Tabs = .home
  @Environment(\.currentUserStore) private var currentUserStore
  @AppStorage(Anime365BaseURL.UserDefaultsKey.BASE_URL, store: Anime365BaseURL.getUserDefaults()) private
    var anime365BaseURL: URL = Anime365BaseURL.DEFAULT_BASE_URL

  var body: some View {
    TabView(selection: self.$selectedTab) {
      Tab(value: .home) {
        NavigationStackWithRouter {
          HomeView()
        }
      } label: {
        Text("Главная")
      }

      if !Anime365BaseURL.isAdultDomain(self.anime365BaseURL) {
        Tab(value: .currentlyWatching) {
          NavigationStackWithRouter {
            CurrentlyWatchingView()
          }
        } label: {
          Text("К просмотру")
        }

        Tab(value: .calendar) {
          NavigationStackWithRouter {
            CalendarView()
          }
        } label: {
          Text("Календарь")
        }
      }

      Tab(value: .profile) {
        NavigationStackWithRouter {
          ProfileView()
        }
      } label: {
        if let userName = currentUserStore.user?.name {
          Text(userName)
        }
        else {
          Text("Профиль")
        }
      }

      Tab(value: .search, role: .search) {
        NavigationStackWithRouter {
          SearchShowsView()
        }
      } label: {
        Image(systemName: "magnifyingglass")
      }
    }
  }
}
