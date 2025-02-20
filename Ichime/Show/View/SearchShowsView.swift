import SwiftUI

@Observable
private class SearchShowsViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded([Show])
  }

  var recentSearches: [String] = UserDefaults.standard.stringArray(forKey: "recentSearches") ?? []

  private(set) var state: State = .idle
  var currentlyTypedSearchQuery = ""
  var isSearchPresented: Bool = false

  private let client: Anime365Client

  private var lastPerformedSearchQuery = ""
  private var currentOffset: Int = 0
  private var shows: [Show] = []
  private var stopLazyLoading: Bool = false

  private let SHOWS_PER_PAGE = 20

  init(client: Anime365Client = ApplicationDependency.container.resolve()) {
    self.client = client
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
      }
      else {
        self.stopLazyLoading = false
        self.currentOffset = self.SHOWS_PER_PAGE
        self.shows = shows
        self.state = .loaded(self.shows)
      }
    }
    catch {
      self.state = .loadingFailed(error)
    }
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
    }
    catch {
      self.stopLazyLoading = true
    }
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
        } actions: {
          Button(action: {
            Task {
              await self.viewModel.performInitialSearch()
            }
          }) {
            Text("Обновить")
          }
        }
        .centeredContentFix()

      case .loadedButEmpty:
        ContentUnavailableView.search
          .centeredContentFix()

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
      text: self.$viewModel.currentlyTypedSearchQuery,
      placement: .automatic,
      prompt: "Название тайтла"
    ) {
      ForEach(self.viewModel.recentSearches, id: \.self) { searchQuery in
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
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 64), count: 2), spacing: 64) {
      ForEach(self.shows) { show in
        ShowCard(show: show, displaySeason: true)
          .frame(height: RawShowCard.RECOMMENDED_HEIGHT)
          .task {
            if show == self.shows.last {
              await self.loadMore()
            }
          }
      }
    }
  }
}
