import SwiftData
import SwiftUI

struct ContentViewWithTabBar: View {
  @AppStorage("ContentViewWithTabView.selectedTab") private var selectedTab: Tabs = .home

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

      Tab(value: .myLists) {
        NavigationStackWithRouter {
          MyListsSelectorView()
        }
      } label: {
        Text("Мой список")
      }

      Tab(value: .profile) {
        NavigationStackWithRouter {
          ProfileView()
        }
      } label: {
        Text("Профиль")
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
