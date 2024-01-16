import SwiftUI

class SearchShowsViewModel: ObservableObject {
    enum State {
        case idle([String])
        case loading
        case loadingFailed(Error)
        case loadedButEmpty
        case loaded([Show])
    }

    @Published private(set) var state: State
    @Published var currentlyTypedSearchQuery = ""
    @Published var isSearchPresented: Bool = false

    private let client: Anime365Client

    private var lastPerformedSearchQuery = ""
    private var currentOffset: Int = 0
    private var shows: [Show] = []
    private var stopLazyLoading: Bool = false
    private var recentSearches = UserDefaults.standard.stringArray(forKey: "recentSearches") ?? []

    private let SHOWS_PER_PAGE = 20

    init() {
        self.state = .idle(self.recentSearches)
        self.client = Anime365Client(
            apiClient: Anime365ApiClient(
                baseURL: "https://anime365.ru/api",
                userAgent: "ani365"
            )
        )
    }

    func performInitialSearch() async {
        if self.currentlyTypedSearchQuery.isEmpty {
            return
        }

        self.state = .loading
        self.lastPerformedSearchQuery = self.currentlyTypedSearchQuery

        self.addRecentSearch(searchQuery: self.currentlyTypedSearchQuery)

        do {
            let shows = try await client.searchShows(
                searchQuery: self.lastPerformedSearchQuery,
                offset: self.currentOffset,
                limit: self.SHOWS_PER_PAGE
            )

            if shows.isEmpty {
                self.state = .loadedButEmpty
            } else {
                self.stopLazyLoading = false
                self.currentOffset = self.SHOWS_PER_PAGE
                self.shows = shows
                self.state = .loaded(self.shows)
            }
        } catch {
            self.state = .loadingFailed(error)
        }
    }

    func performInitialSearchFromRecentSearch(
        searchQuery: String
    ) async {
        self.currentlyTypedSearchQuery = searchQuery
        self.isSearchPresented = true

        await self.performInitialSearch()
    }

    func performLazyLoading() async {
        if self.stopLazyLoading {
            return
        }

        do {
            let shows = try await client.searchShows(
                searchQuery: self.lastPerformedSearchQuery,
                offset: self.currentOffset,
                limit: self.SHOWS_PER_PAGE
            )

            if shows.count < self.SHOWS_PER_PAGE {
                self.stopLazyLoading = true
            }

            self.currentOffset = self.currentOffset + self.SHOWS_PER_PAGE
            self.shows += shows
            self.state = .loaded(self.shows)
        } catch {
            self.stopLazyLoading = true
        }
    }

    func currentlyTypedSearchQueryChanged() {
        if !self.currentlyTypedSearchQuery.isEmpty {
            return
        }

        self.state = .idle(self.recentSearches)
        self.stopLazyLoading = false
        self.currentOffset = 0
        self.shows = []
    }

    private func addRecentSearch(searchQuery: String) {
        var uniqueRecentSearches: [String] = []

        for query in [searchQuery] + self.recentSearches {
            if uniqueRecentSearches.contains(query) {
                continue
            }

            uniqueRecentSearches.append(query)
        }

        uniqueRecentSearches = Array(uniqueRecentSearches.prefix(20))

        self.recentSearches = uniqueRecentSearches

        UserDefaults.standard.set(uniqueRecentSearches, forKey: "recentSearches")
    }
}

struct SearchShowsView: View {
    @ObservedObject var viewModel: SearchShowsViewModel

    var body: some View {
        Group {
            switch self.viewModel.state {
            case .idle(let recentSearches):
                if recentSearches.isEmpty {
                    ContentUnavailableView {
                        Label("Тут пока ничего нет", systemImage: "magnifyingglass")
                    } description: {
                        Text("Предыдущие запросы поиска будут сохраняться на этом экране")
                    }
                } else {
                    List {
                        Section(header: Text("Ранее вы искали")) {
                            ForEach(recentSearches, id: \.self) { searchQuery in
                                Button(action: {
                                    Task {
                                        await self.viewModel.performInitialSearchFromRecentSearch(
                                            searchQuery: searchQuery
                                        )
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

            case .loading:
                ProgressView()

            case .loadingFailed(let error):
                ContentUnavailableView {
                    Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error.localizedDescription)
                }
                .textSelection(.enabled)

            case .loadedButEmpty:
                ContentUnavailableView {
                    Label("Ничего не нашлось", systemImage: "rectangle.grid.3x2.fill")
                } description: {
                    Text("Попробуйте переформулировать текст запроса")
                }

            case .loaded(let shows):
                ScrollView([.vertical]) {
                    ShowsGrid(
                        shows: shows,
                        loadMore: { await self.viewModel.performLazyLoading() }
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
            text: self.$viewModel.currentlyTypedSearchQuery,
            isPresented: self.$viewModel.isSearchPresented,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Название тайтла"
        )
        .onChange(of: self.viewModel.currentlyTypedSearchQuery) {
            self.viewModel.currentlyTypedSearchQueryChanged()
        }
        .onSubmit(of: .search) {
            Task {
                await self.viewModel.performInitialSearch()
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
                    .task {
                        if show == self.shows.last {
                            await self.loadMore()
                        }
                    }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SearchShowsView(viewModel: .init())
    }
}
