//
//  ContentViewWithTabBar.swift
//  Ichime
//
//  Created by p.flaks on 23.03.2024.
//

import SwiftUI

@available(iOS 17.0, *)
@available(tvOS, unavailable)
@available(macOS, unavailable)
@available(watchOS, unavailable)
@available(visionOS, unavailable)
struct ContentViewWithTabBar: View {
    @StateObject private var notificationCounterWatcher: NotificationCounterWatcher = .init()

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Главная", systemImage: "play.house")
            }

            NavigationStack {
                CurrentlyWatchingView()
                    .navigationDestination(for: CurrentlyWatchingView.Navigation.self) { route in
                        if route == .notifications {
                            NotificationCenterView()
                        }
                    }
                    .navigationDestination(
                        for: WatchCardModel.self,
                        destination: { viewEpisodes(show: $0) }
                    )
            }
            .tabItem {
                Label("Я смотрю", systemImage: "play.square.stack")
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

#if os(iOS)
    #Preview {
        ContentViewWithTabBar()
    }
#endif
