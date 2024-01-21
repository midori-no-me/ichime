//
//  ContentView.swift
//  ani365
//
//  Created by p.flaks on 05.01.2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject var manager: VideoPlayerController = .init()

    var body: some View {
        ZStack {
            if UIDevice.current.userInterfaceIdiom == .phone {
                ContentViewWithTabBar()
            } else {
                ContentViewWithSideBar()
            }
        }
        .environmentObject(self.manager)
    }
}

struct ContentViewWithSideBar: View {
    @State private var navigationActiveTab: SideBarLinks? = .ongoings

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
                    CurrentlyWatchingView()
                }

            case .myLists:
                NavigationStack {
                    MyListsView()
                }

            case .notifications:
                NavigationStack {
                    NotificationCenterView()
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
    @EnvironmentObject var scraperManager: Anime365ScraperManager

    var body: some View {
        TabView {
            NavigationStack {
                OngoingsView(viewModel: .init())
            }
            .tabItem {
                Label("Онгоинги", systemImage: "rectangle.grid.3x2.fill")
            }

            NavigationStack {
                CurrentlyWatchingView()
            }
            .tabItem {
                Label("Я смотрю", systemImage: "film.stack")
            }
            .badge(5)

            NavigationStack {
                MyListsView()
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
    AppPreview {
        ContentView()
    }
}
