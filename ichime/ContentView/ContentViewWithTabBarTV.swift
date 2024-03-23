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
                MyListsView()
            }
            .tabItem {
                Text("Мой список")
            }

            NavigationStack {
                NotificationCenterView()
            }
            .tabItem {
                Text("Уведомления")
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
