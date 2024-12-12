import ScraperAPI
import SwiftData
import SwiftUI

struct ContentViewWithSideBar: View {
  @StateObject private var notificationCounterWatcher: NotificationCounterWatcher = .init()
  @Environment(\.modelContext) private var modelContext
  @AppStorage("ContentViewWithTabView.selectedTab") private var selectedTab: Tabs = .home

  @State var viewModel: ShowListStatusModel = ApplicationDependency.container.resolve()

  var body: some View {
    TabView(selection: $selectedTab) {
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
        systemImage: notificationCounterWatcher.counter == 0 ? "bell" : "bell.badge",
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
      await viewModel.cacheCategories()
    }
  }
}
