import OrderedCollections
import SwiftUI

@Observable
private class SearchShowsViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded(OrderedSet<ShowPreview>)
  }

  var recentSearches: [String] = UserDefaults.standard.stringArray(forKey: "recentSearches") ?? []

  var currentlyTypedSearchQuery = ""
  var isSearchPresented: Bool = false

  private var _state: State = .idle
  private let showService: ShowService

  private var lastPerformedSearchQuery = ""
  private var currentOffset: Int = 0
  private var shows: OrderedSet<ShowPreview> = []
  private var stopLazyLoading: Bool = false

  private let SHOWS_PER_PAGE = 20

  private(set) var state: State {
    get {
      self._state
    }
    set {
      withAnimation {
        self._state = newValue
      }
    }
  }

  init(showService: ShowService = ApplicationDependency.container.resolve()) {
    self.showService = showService
  }

  func performSearch() async {
    if self.currentlyTypedSearchQuery.isEmpty {
      return
    }

    self.state = .loading
    self.lastPerformedSearchQuery = self.currentlyTypedSearchQuery

    do {
      let shows = try await showService.searchShows(
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
      let shows = try await showService.searchShows(
        searchQuery: self.lastPerformedSearchQuery,
        offset: self.currentOffset,
        limit: self.SHOWS_PER_PAGE
      )

      if shows.count < self.SHOWS_PER_PAGE {
        self.stopLazyLoading = true
      }

      self.currentOffset = self.currentOffset + self.SHOWS_PER_PAGE
      self.shows = .init(self.shows.elements + shows)
      self.state = .loaded(self.shows)
    }
    catch {
      self.stopLazyLoading = true
    }
  }

  func addRecentSearch() {
    if self.currentlyTypedSearchQuery.isEmpty {
      return
    }

    var uniqueRecentSearches: [String] = []

    for query in [self.currentlyTypedSearchQuery] + self.recentSearches {
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
        ScrollView(.vertical) {
          SearchSuggestionsView()
        }

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
              await self.viewModel.performSearch()
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
        ScrollView(.vertical) {
          LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 64), count: 1), spacing: 64) {
            ForEach(shows) { show in
              ShowCard(
                show: show,
                displaySeason: true,
                onOpened: self.viewModel.addRecentSearch
              )
              .frame(height: RawShowCard.RECOMMENDED_HEIGHT)
              .task {
                if show == shows.last {
                  await self.viewModel.performLazyLoading()
                }
              }
            }
          }
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
        await self.viewModel.performSearch()
      }
    }
    .onChange(of: self.viewModel.currentlyTypedSearchQuery) {
      Task {
        await self.viewModel.performSearch()
      }
    }
  }
}
