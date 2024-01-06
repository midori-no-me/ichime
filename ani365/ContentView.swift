//
//  ContentView.swift
//  ani365
//
//  Created by p.flaks on 05.01.2024.
//

import ScraperAPI
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var client: ScraperClient

    @State private var user: ScraperAPI.Types.User?
    @State private var initialLoad = true

    var body: some View {
        Group {
            if initialLoad {
                ProgressView()
            } else if user == nil {
                NavigationStack {
                    OnboardingView()
                }
            } else {
                if UIDevice.current.userInterfaceIdiom == .phone {
                    ContentViewWithTabBar()
                } else {
                    ContentViewWithSideBar()
                }
            }
        }
        .onReceive(client.inited.dropFirst()) { _ in initialLoad = false }
        .onReceive(client.user) {
            user = $0
        }
    }
}

struct ContentViewWithSideBar: View {
    @State private var navigationActiveTab: SideBarLinks? = .ongoings
    @EnvironmentObject private var scraperClient: ScraperClient
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
    @EnvironmentObject var scraperClient: ScraperClient
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
    AppPreview { _ in
        ContentView()
    }
}
