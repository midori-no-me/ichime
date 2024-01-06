//
//  ContentView.swift
//  ani365
//
//  Created by p.flaks on 01.01.2024.
//

import SwiftUI

struct ContentViewOld: View {
    @State private var shows: [Show] = []
    @State private var isEpisodeViewPresented = false

    private var gridItemLayout = [
        GridItem(.adaptive(minimum: 160), spacing: 10, alignment: .topLeading)
    ]

    var body: some View {
        NavigationSplitView {
            List {
                NavigationLink(destination: SearchShowsView()) {
                    Label("Поиск", systemImage: "magnifyingglass")
                }

                NavigationLink(destination: Text("Main")) {
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
                    ShowCategoryRow(
                        title: "Онгоинги",
                        description: "Сериалы, новые серии которых продолжают выходить",
                        shows: shows
                    )

                    ShowCategoryRow(
                        title: "Новые серии",
                        description: "Из вашего списка",
                        shows: shows
                    )

                }.onAppear {
                    Task {
                        await fetchCards()
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {} label: {
                            Label("Уведомления", systemImage: "bell")
                        }
                    }
                }
                .navigationTitle("Обзор")
            }

            TabView {
                Text("The content of the first view")
                    .tabItem {
                        Image(systemName: "phone.fill")
                        Text("First Tab")
                    }
                Text("The content of the second view")
                    .tabItem {
                        Image(systemName: "tv.fill")
                        Text("Second Tab")
                    }
            }
        }
    }

    func fetchCards() async {
        let anime365Client = Anime365Client(
            apiClient: Anime365ApiClient(
                baseURL: "https://anime365.ru/api",
                userAgent: "ani365"
            )
        )

        do {
            let shows = try await anime365Client.getOngoings()

            DispatchQueue.main.async {
                self.shows = shows
            }
        } catch {
            DispatchQueue.main.async {
                self.shows = []
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentViewOld()
    }
}

#Preview {
    ContentViewOld()
}
