import SwiftData
import SwiftUI

struct ContentViewWithSideBar: View {
  @AppStorage("ContentViewWithTabView.selectedTab") private var selectedTab: Tabs = .home

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
        }
      }

      Tab("Мой список", systemImage: "film.stack", value: .myLists) {
        NavigationStack {
          MyListsSelectorView()
        }
      }

      Tab("Календарь", systemImage: "calendar", value: .calendar) {
        NavigationStack {
          CalendarView()
        }
      }
      Tab("Профиль", systemImage: "person.circle", value: .profile) {
        NavigationStack {
          ProfileView()
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
  }
}
