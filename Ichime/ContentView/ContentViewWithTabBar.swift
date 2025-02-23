import SwiftData
import SwiftUI

struct ContentViewWithTabBar: View {
  @AppStorage("ContentViewWithTabView.selectedTab") private var selectedTab: Tabs = .home
  @AppStorage("enable_hentai_365") private var enabledHentai365: Bool = false

  var body: some View {
    TabView(selection: self.$selectedTab) {
      Tab(value: .home) {
        NavigationStackWithRouter {
          Anime365HomeView()
        }
      } label: {
        Text(self.enabledHentai365 ? "Anime 365" : "Главная")
      }

      if self.enabledHentai365 {
        Tab(value: .homeHentai) {
          NavigationStackWithRouter {
            Hentai365HomeView()
          }
        } label: {
          Text("Hentai 365")
        }
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
