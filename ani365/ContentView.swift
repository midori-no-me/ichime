//
//  ContentView.swift
//  ani365
//
//  Created by p.flaks on 05.01.2024.
//

import SwiftUI

struct ContentView: View {
    let overviewView = OverviewView()
    let ongoingsView = OngoingsView()
    let searchShowsView = SearchShowsView()

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        if horizontalSizeClass == .regular {
            NavigationSplitView {
                List {
                    NavigationLink(destination: searchShowsView) {
                        Label("Поиск", systemImage: "magnifyingglass")
                    }

                    NavigationLink(destination: overviewView) {
                        Label("Обзор", systemImage: "rectangle.grid.2x2")
                    }

                    NavigationLink(destination: ongoingsView) {
                        Label("Онгоинги", systemImage: "film.stack")
                    }

                    Section(header: Text("Моя библиотека")) {
                        NavigationLink(destination: Text("My List")) {
                            Label("Новые серии", systemImage: "play.rectangle.on.rectangle")
                        }
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
                NavigationStack {
                    ScrollView([.vertical]) {
                        Text("....")
                    }
                    .navigationTitle("...")
                }
            }
        } else {
            TabView {
                overviewView
                    .tabItem {
                        Label("Обзор", systemImage: "rectangle.grid.2x2")
                    }
                ongoingsView
                    .tabItem {
                        Label("Онгоинги", systemImage: "film.stack")
                    }
                searchShowsView
                    .tabItem {
                        Label("Поиск", systemImage: "magnifyingglass")
                    }
            }
        }
    }
}

#Preview {
    ContentView()
}
