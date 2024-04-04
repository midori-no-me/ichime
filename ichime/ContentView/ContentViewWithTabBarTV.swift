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
        .onOpenURL(perform: { url in
            guard url.scheme == ServiceLocator.topShellSchema, let components = URLComponents(
                url: url,
                resolvingAgainstBaseURL: true
            ) else {
                return
            }

            guard let action = components.host,
                  let id = components.queryItems?.first(where: { $0.name == "id" })?.value
            else {
                return
            }

            switch action {
            case URLActions.show.rawValue:
                print("its show \(id)")
            case URLActions.episode.rawValue:
                print("its episode \(id)")
            default:
                print("idk")
            }
        })
    }

    enum URLActions: String {
        case show
        case episode
    }
}

// #Preview {
//    ContentViewWithTabBar()
// }
