import OSLog
import OrderedCollections
import SwiftUI

@Observable @MainActor
private final class SearchShowsViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded(shows: OrderedSet<ShowPreviewShikimori>, page: Int, hasMore: Bool)
  }

  private static let SHOWS_PER_PAGE = 10

  private(set) var state: State = .idle

  var recentSearches: [String] = UserDefaults.standard.stringArray(forKey: "recentSearches") ?? []

  var currentlyTypedSearchQuery = ""
  var isSearchPresented: Bool = false

  private let showService: ShowService
  private let logger: Logger

  private var lastPerformedSearchQuery = ""

  init(
    showService: ShowService = ApplicationDependency.container.resolve(),
    logger: Logger = .init(subsystem: ServiceLocator.applicationId, category: "SearchShowsViewModel")
  ) {
    self.showService = showService
    self.logger = logger
  }

  func performInitialLoading(adultOnly: Bool) async {
    if self.currentlyTypedSearchQuery.isEmpty {
      return
    }

    self.updateState(.loading)
    self.lastPerformedSearchQuery = self.currentlyTypedSearchQuery

    do {
      let shows = try await showService.searchShows(
        searchQuery: self.lastPerformedSearchQuery,
        page: 1,
        limit: Self.SHOWS_PER_PAGE,
        adultOnly: adultOnly,
      )

      if shows.isEmpty {
        self.updateState(.loadedButEmpty)
      }
      else {
        self.updateState(
          .loaded(
            shows: shows,
            page: 1,
            hasMore: shows.count == Self.SHOWS_PER_PAGE
          )
        )
      }
    }
    catch {
      self.updateState(.loadingFailed(error))
    }
  }

  func performLazyLoading(adultOnly: Bool) async {
    guard case let .loaded(alreadyLoadedShows, page, hasMore) = state else {
      return
    }

    if !hasMore {
      return
    }

    do {
      let shows = try await showService.searchShows(
        searchQuery: self.lastPerformedSearchQuery,
        page: page + 1,
        limit: Self.SHOWS_PER_PAGE,
        adultOnly: adultOnly,
      )

      self.updateState(
        .loaded(
          shows: .init(alreadyLoadedShows.elements + shows),
          page: page + 1,
          hasMore: shows.count == Self.SHOWS_PER_PAGE
        )
      )
    }
    catch {
      self.logger.debug("Stop lazy loading due to exception: \(error)")
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

  private func updateState(_ state: State) {
    withAnimation(.easeInOut(duration: 0.5)) {
      self.state = state
    }
  }
}

struct SearchShowsView: View {
  @State private var viewModel: SearchShowsViewModel = .init()

  @AppStorage(Anime365BaseURL.UserDefaultsKey.BASE_URL, store: Anime365BaseURL.getUserDefaults()) private
    var anime365BaseURL: URL = Anime365BaseURL.DEFAULT_BASE_URL

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
              await self.viewModel.performInitialLoading(adultOnly: Anime365BaseURL.isAdultDomain(self.anime365BaseURL))
            }
          }) {
            Text("Обновить")
          }
        }
        .centeredContentFix()

      case .loadedButEmpty:
        ContentUnavailableView.search
          .centeredContentFix()

      case let .loaded(shows, _, _):
        ScrollView(.vertical) {
          LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: ShowCard.RECOMMENDED_SPACING), count: 3),
            spacing: ShowCard.RECOMMENDED_SPACING
          ) {
            ForEach(shows) { show in
              ShowCardMyAnimeList(
                show: show,
                displaySeason: true,
                onOpened: self.viewModel.addRecentSearch
              )
              .task {
                if show == shows.last {
                  await self.viewModel.performLazyLoading(
                    adultOnly: Anime365BaseURL.isAdultDomain(self.anime365BaseURL)
                  )
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
        await self.viewModel.performInitialLoading(adultOnly: Anime365BaseURL.isAdultDomain(self.anime365BaseURL))
      }
    }
    .onChange(of: self.viewModel.currentlyTypedSearchQuery) {
      Task {
        await self.viewModel.performInitialLoading(adultOnly: Anime365BaseURL.isAdultDomain(self.anime365BaseURL))
      }
    }
  }
}
