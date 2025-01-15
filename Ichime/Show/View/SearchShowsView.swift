import SwiftUI

@Observable
class SearchShowsViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded([Show])
  }

  private(set) var state: State = .idle
  var currentlyTypedSearchQuery = ""
  var isSearchPresented: Bool = false

  private let client: Anime365Client

  private var lastPerformedSearchQuery = ""
  private var currentOffset: Int = 0
  private var shows: [Show] = []
  private var stopLazyLoading: Bool = false
  public var recentSearches: [String] = UserDefaults.standard.stringArray(forKey: "recentSearches") ?? []

  private let SHOWS_PER_PAGE = 20

  init(client: Anime365Client = ApplicationDependency.container.resolve()) {
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
      }
      else {
        stopLazyLoading = false
        currentOffset = SHOWS_PER_PAGE
        self.shows = shows
        state = .loaded(self.shows)
      }
    }
    catch {
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
    }
    catch {
      stopLazyLoading = true
    }
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
  @State private var viewModel: SearchShowsViewModel = .init()

  var body: some View {
    Group {
      switch self.viewModel.state {
      case .idle:
        Color.clear

      case .loading:
        ProgressView()
          .focusable()

      case let .loadingFailed(error):
        ContentUnavailableView {
          Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
        } description: {
          Text(error.localizedDescription)
        }

      case .loadedButEmpty:
        ContentUnavailableView.search

      case let .loaded(shows):
        ScrollView([.vertical]) {
          ShowsGrid(
            shows: shows,
            loadMore: { await self.viewModel.performLazyLoading() }
          )
          .padding(.top, RawShowCard.RECOMMENDED_SPACING)
          .padding(.leading, RawShowCard.RECOMMENDED_SPACING)
        }
      }
    }
    .searchable(
      text: $viewModel.currentlyTypedSearchQuery,
      placement: .automatic,
      prompt: "Название тайтла"
    ) {
      ForEach(viewModel.recentSearches, id: \.self) { searchQuery in
        Text(searchQuery)
          .searchCompletion(searchQuery)
      }
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
    LazyVGrid(
      columns: [
        GridItem(
          .adaptive(minimum: RawShowCard.RECOMMENDED_MINIMUM_WIDTH),
          spacing: RawShowCard.RECOMMENDED_SPACING,
          alignment: .topLeading
        )
      ],
      spacing: RawShowCard.RECOMMENDED_SPACING
    ) {
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
