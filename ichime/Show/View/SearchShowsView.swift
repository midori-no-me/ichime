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

    init(client: Anime365Client = ApplicationDependency.container.resolve()) {
        state = .idle(recentSearches)
        self.client = client
    }

    func performInitialSearch() async {
        if currentlyTypedSearchQuery.isEmpty {
            return
        }

        state = .loading
        lastPerformedSearchQuery = currentlyTypedSearchQuery

        addRecentSearch(searchQuery: currentlyTypedSearchQuery)

        do {
            let shows = try await client.searchShows(
                searchQuery: lastPerformedSearchQuery,
                offset: currentOffset,
                limit: SHOWS_PER_PAGE
            )

            if shows.isEmpty {
                state = .loadedButEmpty
            } else {
                stopLazyLoading = false
                currentOffset = SHOWS_PER_PAGE
                self.shows = shows
                state = .loaded(self.shows)
            }
        } catch {
            state = .loadingFailed(error)
        }
    }

    func performInitialSearchFromRecentSearch(
        searchQuery: String
    ) async {
        currentlyTypedSearchQuery = searchQuery

        await performInitialSearch()
    }

    func performLazyLoading() async {
        if stopLazyLoading {
            return
        }

        do {
            let shows = try await client.searchShows(
                searchQuery: lastPerformedSearchQuery,
                offset: currentOffset,
                limit: SHOWS_PER_PAGE
            )

            if shows.count < SHOWS_PER_PAGE {
                stopLazyLoading = true
            }

            currentOffset = currentOffset + SHOWS_PER_PAGE
            self.shows += shows
            state = .loaded(self.shows)
        } catch {
            stopLazyLoading = true
        }
    }

    func currentlyTypedSearchQueryChanged() {
        if !currentlyTypedSearchQuery.isEmpty {
            return
        }

        state = .idle(recentSearches)
        stopLazyLoading = false
        currentOffset = 0
        shows = []
    }

    private func addRecentSearch(searchQuery: String) {
        var uniqueRecentSearches: [String] = []

        for query in [searchQuery] + recentSearches {
            if uniqueRecentSearches.contains(query) {
                continue
            }

            uniqueRecentSearches.append(query)
        }

        uniqueRecentSearches = Array(uniqueRecentSearches.prefix(20))

        recentSearches = uniqueRecentSearches

        UserDefaults.standard.set(uniqueRecentSearches, forKey: "recentSearches")
    }
}

struct SearchShowsView: View {
    @StateObject private var viewModel: SearchShowsViewModel = .init()

    var body: some View {
        Group {
            switch self.viewModel.state {
            case let .idle(recentSearches):
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
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                    .listStyle(.plain)
                }

            case .loading:
                ProgressView()
                #if os(tvOS)
                    .focusable()
                #endif

            case let .loadingFailed(error):
                ContentUnavailableView {
                    Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error.localizedDescription)
                }
                #if !os(tvOS)
                .textSelection(.enabled)
                #endif

            case .loadedButEmpty:
                ContentUnavailableView.search

            case let .loaded(shows):
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
        #if os(iOS) // !is(tvOS)
        .navigationBarTitleDisplayMode(.large)
        .searchable(
            text: $viewModel.currentlyTypedSearchQuery,
            isPresented: $viewModel.isSearchPresented,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Название тайтла"
        )
        #endif
        #if os(macOS)
        .searchable(
            text: $viewModel.currentlyTypedSearchQuery,
            isPresented: $viewModel.isSearchPresented,
            placement: .toolbar,
            prompt: "Название тайтла"
        )
        #endif
        .onChange(of: viewModel.currentlyTypedSearchQuery) {
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
    let loadMore: () async -> Void

    var body: some View {
        LazyVGrid(columns: [
            GridItem(
                .adaptive(minimum: RawShowCard.RECOMMENDED_MINIMUM_WIDTH),
                spacing: RawShowCard.RECOMMENDED_SPACING,
                alignment: .topLeading
            ),
        ], spacing: RawShowCard.RECOMMENDED_SPACING) {
            ForEach(self.shows) { show in
                ShowCard(show: show, displaySeason: true)
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
        SearchShowsView()
    }
}
