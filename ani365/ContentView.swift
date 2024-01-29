//
//  ContentView.swift
//  ani365
//
//  Created by p.flaks on 05.01.2024.
//

import ScraperAPI
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var scraperManager: ScraperClient

    @State private var user: ScraperAPI.Types.User?

    var body: some View {
        Group {
            if user == nil {
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
        }.onReceive(scraperManager.user) { user = $0 }
    }
}

struct ContentViewWithSideBar: View {
    @State private var navigationActiveTab: SideBarLinks? = .ongoings
    @EnvironmentObject private var scraperClient: ScraperClient

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
                        .badge(5)
                        .tag(SideBarLinks.notifications)
                }
            }
            .navigationTitle("Anime 365")

        } detail: {
            switch navigationActiveTab {
            case .searchShows:
                NavigationStack {
                    SearchShowsView(viewModel: .init())
                }

            case .ongoings:
                NavigationStack {
                    OngoingsView(viewModel: .init())
                }

            case .currentlyWatching:
                NavigationStack {
                    CurrentlyWatchingView(viewModel: .init(apiClient: scraperClient))
                }

            case .myLists:
                NavigationStack {
                    MyListsView(viewModel: .init(apiClient: scraperClient))
                }

            case .notifications:
                NavigationStack {
                    NotificationCenterView(viewModel: .init(apiClient: scraperClient))
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
    @State private var counter = 0

    var body: some View {
        TabView {
            NavigationStack {
                OngoingsView(viewModel: .init())
            }
            .tabItem {
                Label("Онгоинги", systemImage: "rectangle.grid.3x2.fill")
            }

            NavigationStack {
                CurrentlyWatchingView(viewModel: .init(apiClient: scraperClient))
            }
            .tabItem {
                Label("Я смотрю", systemImage: "film.stack")
            }
            .badge(counter)
            .onReceive(scraperClient.counter) { counter = $0 }

            NavigationStack {
                MyListsView(viewModel: .init(apiClient: scraperClient))
            }
            .tabItem {
                Label("Мой список", systemImage: "list.and.film")
            }

            NavigationStack {
                SearchShowsView(viewModel: .init())
            }
            .tabItem {
                Label("Поиск", systemImage: "magnifyingglass")
            }
        }
    }
}

#Preview {
    AppPreview { _ in
        ContentView()
    }
}
