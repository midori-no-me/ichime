//
//  ContentView.swift
//  ichime
//
//  Created by p.flaks on 05.01.2024.
//

import ScraperAPI
import SwiftUI

struct ContentView: View {
    private var userManager: UserManager = ApplicationDependency.container.resolve()

    var body: some View {
        Group {
            switch userManager.state {
            case .idle:
                Color.clear.onAppear {
                    Task {
                        await userManager.checkAuth()
                    }
                }
            case .loading:
                ProgressView()
            case .isAuth:
                if UIDevice.current.userInterfaceIdiom == .phone {
                    ContentViewWithTabBar()
                } else {
                    ContentViewWithSideBar()
                }
            case .isAnonym:
                NavigationStack {
                    OnboardingView()
                }
            }
        }
    }
}

struct ContentViewWithSideBar: View {
    @State private var navigationActiveTab: SideBarLinks? = .ongoings
    @StateObject private var notificationCounterWatcher: NotificationCounterWatcher = .init()
    @StateObject private var videoPlayerController: VideoPlayerController = .init()

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
                    CurrentlyWatchingView()
                        .navigationDestination(
                            for: WatchCardModel.self,
                            destination: { viewShow(show: $0, videoPlayerController: videoPlayerController) }
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
                                destination: { viewShow(show: $0, videoPlayerController: videoPlayerController) }
                            )
                        if videoPlayerController.loading {
                            VideoPlayerLoader()
                        }
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

struct ContentViewWithTabBar: View {
    @StateObject private var notificationCounterWatcher: NotificationCounterWatcher = .init()
    @StateObject private var videoPlayerController: VideoPlayerController = .init()

    var body: some View {
        TabView {
            NavigationStack {
                OngoingsView()
            }
            .tabItem {
                Label("Онгоинги", systemImage: "rectangle.grid.3x2.fill")
            }

            NavigationStack {
                CurrentlyWatchingView()
                    .navigationDestination(for: CurrentlyWatchingView.SubRoute.self) { route in
                        if route == .notifications {
                            ZStack {
                                NotificationCenterView()
                                if videoPlayerController.loading {
                                    VideoPlayerLoader()
                                }
                            }
                        }
                    }
                    .navigationDestination(
                        for: WatchCardModel.self,
                        destination: { viewShow(show: $0, videoPlayerController: videoPlayerController)
                        }
                    )
            }
            .tabItem {
                Label("Я смотрю", systemImage: "film.stack")
            }
            .badge(notificationCounterWatcher.counter)

            NavigationStack {
                MyListsView()
            }
            .tabItem {
                Label("Мой список", systemImage: "list.and.film")
            }

            NavigationStack {
                SearchShowsView()
            }
            .tabItem {
                Label("Поиск", systemImage: "magnifyingglass")
            }
        }
    }
}

@ViewBuilder
func viewShow(show: WatchCardModel, videoPlayerController: VideoPlayerController) -> some View {
    if show.type == .notication {
        EpisodeTranslationQualitySelectorView(
            translationId: show.id,
            translationTeam: show.title,
            videoPlayerController: videoPlayerController
        )
    }
    if show.type == .show {
        EpisodeTranslationsView(
            episodeId: show.id,
            episodeTitle: show.title
        )
    }
}

#Preview {
    ContentView()
}
