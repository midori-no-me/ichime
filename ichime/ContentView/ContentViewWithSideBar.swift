//
//  ContentViewWithSideBar.swift
//  ichime
//
//  Created by Nikita Nafranets on 14.03.2024.
//

import SwiftUI

@available(iOS 17.0, *)
@available(macOS 14.0, *)
@available(tvOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
struct ContentViewWithSideBar: View {
    @State private var navigationActiveTab: SideBarLinks? = .home
    @StateObject private var notificationCounterWatcher: NotificationCounterWatcher = .init()

    enum SideBarLinks {
        case searchShows
        case home
        case currentlyWatching
        case myLists
        case notifications
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $navigationActiveTab) {
                Label("Поиск", systemImage: "magnifyingglass")
                    .tag(SideBarLinks.searchShows)

                Label("Главная", systemImage: "play.house")
                    .tag(SideBarLinks.home)

                Section(header: Text("Моя библиотека")) {
                    Label("Я смотрю", systemImage: "play.square.stack")
                        .tag(SideBarLinks.currentlyWatching)

                    Label("Мой список", systemImage: "list.and.film")
                        .tag(SideBarLinks.myLists)

                    Label("Уведомления", systemImage: notificationCounterWatcher.counter == 0 ? "bell" : "bell.badge")
                    #if !os(tvOS)
                        .badge(notificationCounterWatcher.counter)
                    #endif
                        .tag(SideBarLinks.notifications)
                }
            }
            .navigationTitle("Ichime")

        } detail: {
            switch navigationActiveTab {
            case .searchShows:
                NavigationStack {
                    SearchShowsView()
                }

            case .home:
                NavigationStack {
                    HomeView()
                }

            case .currentlyWatching:
                NavigationStack {
                    CurrentlyWatchingView()
                        .navigationDestination(
                            for: WatchCardModel.self,
                            destination: { viewEpisodes(show: $0) }
                        )
                }

            case .myLists:
                NavigationStack {
                    MyListsView()
                }

            case .notifications:
                NavigationStack {
                    ZStack {
                        NotificationCenterView()
                            .navigationDestination(
                                for: WatchCardModel.self,
                                destination: { viewEpisodes(show: $0) }
                            )
                    }
                }

            default:
                ContentUnavailableView {
                    Label("Тут ничего нет", systemImage: "sidebar.leading")
                } description: {
                    Text("Выберите любую вкладку в левом меню")
                }
            }
        }
    }
}

// #Preview {
//    ContentViewWithSideBar()
// }
