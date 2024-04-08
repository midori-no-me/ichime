import SwiftUI

@available(tvOS 17.0, *)
@available(iOS, unavailable)
@available(macOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
struct ContentViewWithTabBarTV: View {
    @StateObject private var notificationCounterWatcher: NotificationCounterWatcher = .init()
    @State var selectedTab: Tabs = .home
    @State var topShelfNavigation = NavigationPath()

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Text("Главная")
            }
            .tag(Tabs.home)

            NavigationStack(path: $topShelfNavigation) {
                CurrentlyWatchingView()
                    .navigationDestination(
                        for: WatchCardModel.self,
                        destination: { viewEpisodes(show: $0) }
                    )
                    .navigationDestination(for: Route.self, destination: { route in
                        switch route.type {
                        case .show:
                            ShowView(showId: route.id)
                        case .episode:
                            EpisodeTranslationsView(episodeId: route.id, episodeTitle: route.title ?? "No name")
                        }
                    })
            }
            .tabItem {
                Text("Я смотрю")
            }
            .tag(Tabs.watch)

            NavigationStack {
                NotificationCenterView()
                    .navigationDestination(
                        for: WatchCardModel.self,
                        destination: { viewEpisodes(show: $0) }
                    )
            }
            .tabItem {
                Text("Уведомления")
            }.tag(Tabs.notifications)

            NavigationStack {
                MyListsView()
            }
            .tabItem {
                Text("Мой список")
            }.tag(Tabs.myList)

            NavigationStack {
                ProfileSheet()
            }
            .tabItem {
                Text("Профиль")
            }.tag(Tabs.profile)

            NavigationStack {
                SearchShowsView()
            }
            .tabItem {
                Image(systemName: "magnifyingglass")
            }.tag(Tabs.search)
        }
        .onOpenURL(perform: { url in
            guard url.scheme == ServiceLocator.topShellSchema, let components = URLComponents(
                url: url,
                resolvingAgainstBaseURL: true
            ) else {
                return
            }

            guard let action = components.host,
                  let rawId = components.queryItems?.first(where: { $0.name == "id" })?.value,
                  let id = Int(rawId)
            else {
                return
            }

            let episodeTitle = components.queryItems?.first(where: { $0.name == "title" })?.value

            switch action {
            case URLActions.show.rawValue:
                print("its show \(id)")
                selectedTab = .watch
                topShelfNavigation.append(Route(id: id, type: .show, title: nil))
            case URLActions.episode.rawValue:
                print("its episode \(id)")
                selectedTab = .watch
                topShelfNavigation.append(Route(id: id, type: .episode, title: episodeTitle))
            default:
                print("idk")
            }
        })
    }

    enum URLActions: String {
        case show
        case episode
    }

    struct Route: Hashable {
        let id: Int
        let type: URLActions
        let title: String?
    }

    enum Tabs: String, Hashable {
        case home
        case watch
        case notifications
        case myList
        case profile
        case search
    }
}

// #Preview {
//    ContentViewWithTabBar()
// }
