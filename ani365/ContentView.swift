//
//  ContentView.swift
//  ani365
//
//  Created by p.flaks on 05.01.2024.
//

import SwiftUI

struct EpisodeWrapper: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Episode {
        return Episode()
    }

    func updateUIViewController(_ uiViewController: Episode, context: Context) {
        // Update the view controller if needed
    }
}

struct ContentView: View {
    @State private var isEpisodeViewPresented = false

    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        if horizontalSizeClass == .regular {
            NavigationSplitView {
                List {
                    NavigationLink(destination: SearchShowsView(), label: {
                        Label("Поиск", systemImage: "magnifyingglass")
                    })

                    NavigationLink(destination: OverviewView()) {
                        Label("Обзор", systemImage: "rectangle.grid.2x2")
                    }

                    NavigationLink(destination: OngoingsView()) {
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

                    Button(
                        action: {
                            self.isEpisodeViewPresented = true
                        },
                        label: {
                            Text("Show Episode")
                        }
                    )
                    .sheet(isPresented: $isEpisodeViewPresented) {
                        EpisodeWrapper() // Use the wrapper to present the UIKit view controller
                    }
                }
            }
        } else {
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
            }
        }
    }
}

#Preview {
    ContentView()
}
