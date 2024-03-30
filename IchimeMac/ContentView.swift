//
//  ContentView.swift
//  IchimeMac
//
//  Created by Nikita Nafranets on 12.03.2024.
//

import SwiftUI

struct ContentView: View {
    private var userManager: UserManager = ApplicationDependency.container.resolve()

    var body: some View {
        switch userManager.state {
        case .idle:
            Color.clear.onAppear {
                Task {
                    await userManager.checkAuth()
                }
            }
        case .loading:
            ProgressView()
            #if os(tvOS)
                .focusable()
            #endif
        case .isAuth:
            ContentViewWithSideBar()
        case .isAnonym:
            NavigationStack {
                OnboardingView()
            }
        }
    }
}

struct ContentViewWithSideBar: View {
    @State private var navigationActiveTab: SideBarLinks? = .ongoings
    @StateObject private var notificationCounterWatcher: NotificationCounterWatcher = .init()

    enum SideBarLinks {
        case searchShows
        case ongoings
        case currentlyWatching
        case myLists
        case notifications
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $navigationActiveTab) {
                Label("Поиск", systemImage: "magnifyingglass")
                    .tag(SideBarLinks.searchShows)

                Label("Онгоинги", systemImage: "rectangle.grid.3x2.fill")
                    .tag(SideBarLinks.ongoings)

                Section(header: Text("Моя библиотека")) {
                    Label("Я смотрю", systemImage: "film.stack")
                        .tag(SideBarLinks.currentlyWatching)

                    Label("Мой список", systemImage: "list.and.film")
                        .tag(SideBarLinks.myLists)

                    Label("Уведомления", systemImage: "bell")
                        .badge(notificationCounterWatcher.counter)
                        .tag(SideBarLinks.notifications)
                }
            }
            .navigationTitle("Anime 365")

        } detail: {
            switch navigationActiveTab {
            case .searchShows:
                NavigationStack {
                    SearchShowsView()
                }

            case .ongoings:
                NavigationStack {
                    OngoingsView()
                }

            case .currentlyWatching:
                NavigationStack {
                    Text("currentwatch")
//                    CurrentlyWatchingView()
//                        .navigationDestination(
//                            for: WatchCardModel.self,
//                            destination: { viewShow(show: $0, videoPlayerController: videoPlayerController) }
//                        )
                }

            case .myLists:
                NavigationStack {
                    Text("mylists")
//                    MyListsView()
                }

            case .notifications:
                NavigationStack {
                    ZStack {
                        Text("Notifications")
//                        NotificationCenterView()
//                            .navigationDestination(
//                                for: WatchCardModel.self,
//                                destination: { viewShow(show: $0, videoPlayerController: videoPlayerController) }
//                            )
//                        if videoPlayerController.loading {
//                            VideoPlayerLoader()
//                        }
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

#Preview {
    ContentViewWithSideBar()
}

#Preview {
    ContentView()
}
