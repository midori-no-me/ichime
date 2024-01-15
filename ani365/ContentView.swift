//
//  ContentView.swift
//  ani365
//
//  Created by p.flaks on 05.01.2024.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        if UIDevice.current.userInterfaceIdiom == .phone {
            ContentViewWithTabBar()
        } else {
            ContentViewWithSideBar()
        }
    }
}

struct ContentViewWithSideBar: View {
    @State private var isEpisodeViewPresented = false
    @State private var navigationActiveTab: SideBarLinks? = .overview

    enum SideBarLinks {
        case overview
        case searchShows
        case ongoings
        case newEpisodes
        case onboarding
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $navigationActiveTab) {
                Label("Поиск", systemImage: "magnifyingglass")
                    .tag(SideBarLinks.searchShows)

                Label("Обзор", systemImage: "rectangle.grid.2x2")
                    .tag(SideBarLinks.overview)

                Label("Онгоинги", systemImage: "film.stack")
                    .tag(SideBarLinks.ongoings)

                Section(header: Text("Моя библиотека")) {
                    Label("Новые серии", systemImage: "play.rectangle.on.rectangle")
                        .tag(SideBarLinks.newEpisodes)

                    Label("Онбординг", systemImage: "person.circle")
                        .tag(SideBarLinks.onboarding)
                }
            }
            .navigationTitle("Anime 365")
            .listStyle(SidebarListStyle())
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {} label: {
                        Label("Уведомления", systemImage: "bell")
                    }
                }
            }

        } detail: {
            switch navigationActiveTab {
            case .overview:
                NavigationStack {
                    OverviewView()
                }

            case .searchShows:
                NavigationStack {
                    SearchShowsView()
                }

            case .ongoings:
                NavigationStack {
                    OngoingsView()
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
                OverviewView()
            }
            .tabItem {
                Label("Обзор", systemImage: "rectangle.grid.2x2")
            }

            NavigationStack {
                OngoingsView()
            }
            .tabItem {
                Label("Онгоинги", systemImage: "film.stack")
            }

            NavigationStack {
                SearchShowsView()
            }
            .tabItem {
                Label("Поиск", systemImage: "magnifyingglass")
            }

            NavigationStack {
                OnboardingView()
            }
            .tabItem {
                Label("Онбординг", systemImage: "person.circle")
            }
        }
    }
}

#Preview {
    AppPreview {
        ContentView()
    }
}
