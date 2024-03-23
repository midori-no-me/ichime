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
                OngoingsView()
            }
            .tabItem {
                Text("Онгоинги")
            }

            NavigationStack {
                CurrentlyWatchingView()
            }
            .tabItem {
                Text("Я смотрю")
            }

            NavigationStack {
                NotificationCenterView()
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

//#Preview {
//    ContentViewWithTabBar()
//}
