import SwiftUI

@available(tvOS 17.0, *)
@available(iOS, unavailable)
@available(macOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
struct ContentViewWithTabBarTV: View {
    @StateObject private var notificationCounterWatcher: NotificationCounterWatcher = .init()

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Text("Главная")
            }

            NavigationStack {
                CurrentlyWatchingView()
                    .navigationDestination(
                        for: WatchCardModel.self,
                        destination: { viewEpisodes(show: $0) }
                    )
            }
            .tabItem {
                Text("Я смотрю")
            }

            NavigationStack {
                NotificationCenterView()
                    .navigationDestination(
                        for: WatchCardModel.self,
                        destination: { viewEpisodes(show: $0) }
                    )
            }
            .tabItem {
                Text("Уведомления")
            }

            NavigationStack {
                MyListsView()
            }
            .tabItem {
                Text("Мой список")
            }

            NavigationStack {
                ProfileSheet()
            }
            .tabItem {
                Text("Профиль")
            }

            NavigationStack {
                SearchShowsView()
            }
            .tabItem {
                Image(systemName: "magnifyingglass")
            }
        }
    }
}

// #Preview {
//    ContentViewWithTabBar()
// }
