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
