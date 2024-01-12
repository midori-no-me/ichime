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
    var id: String { self.name }
    var name: String
}

struct SearchShowsView: View {
    @State private var shows: [Show] = []
    @State private var currentOffset = 0
    @State private var searchQuery = ""
    @State private var isLoading = false
    @State private var loadingError: Error?
    @State private var stopLazyLoading = false
    @State private var isSearchPresented = false

    @State private var recentSearches: [String] = UserDefaults.standard.stringArray(forKey: "recentSearches") ?? []

    private let SHOWS_PER_PAGE = 20

    var body: some View {
        Group {
            if self.isLoading {
                ProgressView()

            } else if let loadingError = self.loadingError {
                ContentUnavailableView {
                    Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(loadingError.localizedDescription)
                }
                .textSelection(.enabled)

            } else if self.searchQuery.isEmpty || (self.shows.isEmpty && self.isSearchPresented) {
                if self.recentSearches.isEmpty {
                    ContentUnavailableView {
                        Label("Тут пока ничего нет", systemImage: "magnifyingglass")
                    } description: {
                        Text("Предыдущие запросы поиска будут сохраняться на этом экране")
                    }

                } else {
                    List {
                        Section(header: Text("Ранее вы искали")) {
                            ForEach(self.recentSearches, id: \.self) { searchQuery in
                                Button(action: {
                                    Task {
                                        self.shows = []
                                        self.searchQuery = searchQuery
                                        self.isLoading = true
                                        self.loadingError = nil
                                        self.stopLazyLoading = false
                                        self.isSearchPresented = true

                                        await self.fetchShows(searchText: searchQuery, offset: 0)
                                    }
                                }) {
                                    Text(searchQuery)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                    .listStyle(.plain)
                }

            } else if self.shows.isEmpty {
                ContentUnavailableView {
                    Label("Ничего не нашлось", systemImage: "rectangle.grid.3x2.fill")
                } description: {
                    Text("Кажется, где-то закрался баг 😭")
                }

            } else {
                ScrollView([.vertical]) {
                    ShowsGrid(
                        shows: self.shows,
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
            isPresented: self.$isSearchPresented,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Название тайтла"
        )
        .onSubmit(of: .search) {
            if self.searchQuery.isEmpty {
                return
            }

            Task {
                self.shows = []
                self.isLoading = true
                self.loadingError = nil
                self.stopLazyLoading = false
                self.recentSearches.insert(self.searchQuery, at: 0)
                UserDefaults.standard.set(self.recentSearches, forKey: "recentSearches")

                await self.fetchShows(searchText: self.searchQuery, offset: 0)
            }
        }
    }

    private func fetchShows(
        searchText: String,
        offset: Int
    ) async {
        if searchText.isEmpty || self.stopLazyLoading {
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
                limit: self.SHOWS_PER_PAGE
            )

            self.shows += shows
            self.currentOffset = offset

            if shows.count < self.SHOWS_PER_PAGE {
                self.stopLazyLoading = true
            }
        } catch {
            self.loadingError = error
        }

        self.isLoading = false
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
