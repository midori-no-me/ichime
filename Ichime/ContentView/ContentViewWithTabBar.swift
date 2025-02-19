import SwiftData
import SwiftUI

struct ContentViewWithTabBar: View {
  @AppStorage("ContentViewWithTabView.selectedTab") private var selectedTab: Tabs = .home

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

      Tab(value: .profile) {
        NavigationStack {
          ProfileView()
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
  }
}
