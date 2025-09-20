import SwiftData
import SwiftUI

struct ContentViewWithTabBar: View {
  @AppStorage("ContentViewWithTabView.selectedTab") private var selectedTab: Tabs = .home
  @AppStorage(CurrentUserInfo.UserDefaultsKey.NAME) private var userName: String?

  var body: some View {
    TabView(selection: self.$selectedTab) {
      Tab(value: .home) {
        NavigationStackWithRouter {
          HomeView()
        }
      } label: {
        Text("Главная")
      }

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

      Tab(value: .profile) {
        NavigationStackWithRouter {
          ProfileView()
        }
      } label: {
        if let userName {
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
