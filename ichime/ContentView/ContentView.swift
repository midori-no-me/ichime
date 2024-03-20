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
                if UIDevice.current.userInterfaceIdiom == .tv || UIDevice.current.userInterfaceIdiom == .phone {
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

struct ContentViewWithTabBar: View {
    @StateObject private var notificationCounterWatcher: NotificationCounterWatcher = .init()

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
                            }
                        }
                    }
                    .navigationDestination(
                        for: WatchCardModel.self,
                        destination: { viewShow(show: $0) }
                    )
            }
            .tabItem {
                Label("Я смотрю", systemImage: "film.stack")
            }
            #if !os(tvOS)
            .badge(notificationCounterWatcher.counter)
            #endif

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
func viewShow(show: WatchCardModel) -> some View {
    EpisodeTranslationsView(
        episodeId: show.data.episode,
        episodeTitle: show.data.title,
        preselectedTranslation: show.data.translation
    )
}

#Preview {
    ContentView()
}
