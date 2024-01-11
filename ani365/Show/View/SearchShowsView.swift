//
//  SearchShowsView.swift
//  ani365
//
//  Created by p.flaks on 05.01.2024.
//

import SwiftUI

// https://www.hackingwithswift.com/quick-start/swiftui/how-to-add-a-search-bar-to-filter-your-data

enum SearchScope: String, CaseIterable {
    case ongoing
}

// Holds one token that we want the user to filter by. This *must* conform to Identifiable.
struct Token: Identifiable {
    var id: String { name }
    var name: String
}

struct SearchShowsView: View {
    @State private var shows: [Show] = []
    @State private var currentOffset = 0
    @State private var searchQuery = ""
    @State private var loadingError: Error?
    @State private var isSearchPresented = false

    private let SHOWS_PER_PAGE = 20

    var body: some View {
        Group {
            if let loadingError = self.loadingError {
                ContentUnavailableView {
                    Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(loadingError.localizedDescription)
                }
                .textSelection(.enabled)

            } else if isSearchPresented && shows.isEmpty {
                Text("Введите название сериала")
                    .foregroundStyle(.secondary)

            } else if searchQuery.isEmpty {
                ContentUnavailableView {
                    Label("Тут пока ничего нет", systemImage: "magnifyingglass")
                } description: {
                    Text("Предыдущие запросы поиска будут сохраняться на этом экране")
                }
                .textSelection(.enabled)

            } else if shows.isEmpty {
                ContentUnavailableView {
                    Label("Ничего не нашлось", systemImage: "rectangle.grid.3x2.fill")
                } description: {
                    Text("Кажется, где-то закрался баг 😭")
                }

            } else {
                ScrollView([.vertical]) {
                    ShowsGrid(
                        shows: shows,
                        loadMore: {
                            await self.fetchShows(
                                searchText: self.searchQuery,
                                offset: self.currentOffset + self.SHOWS_PER_PAGE
                            )
                        }
                    )
                    .padding(.top, 18)
                    .scenePadding(.horizontal)
                    .scenePadding(.bottom)
                }
            }
        }
        .navigationTitle("Поиск")
        .navigationBarTitleDisplayMode(.large)
        .searchable(
            text: self.$searchQuery,
            isPresented: $isSearchPresented,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Название тайтла"
        )
        .onSubmit(of: .search) {
            Task {
                await fetchShows(searchText: searchQuery, offset: 0)
            }
        }
    }

    private func fetchShows(
        searchText: String,
        offset: Int
    ) async {
        if searchText.isEmpty {
            shows = []

            return
        }

        let anime365Client = Anime365Client(
            apiClient: Anime365ApiClient(
                baseURL: "https://anime365.ru/api",
                userAgent: "ani365"
            )
        )

        do {
            let shows = try await anime365Client.searchShows(
                searchQuery: searchText,
                offset: offset,
                limit: SHOWS_PER_PAGE
            )

            DispatchQueue.main.async {
                self.shows = shows
            }
        } catch {
            DispatchQueue.main.async {
                self.loadingError = error
            }
        }
    }
}

private struct ShowsGrid: View {
    let shows: [Show]
    let loadMore: () async -> ()

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12, alignment: .topLeading)], spacing: 18) {
            ForEach(self.shows) { show in
                ShowCard(show: show)
                    .frame(height: 300)
                    .onAppear {
                        Task {
                            if show == self.shows.last {
                                await self.loadMore()
                            }
                        }
                    }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SearchShowsView()
    }
}
