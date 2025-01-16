import SwiftUI

class FilteredShowsViewModel: ObservableObject {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded([Show])
  }

  @Published private(set) var state: State = .idle

  private var currentOffset: Int = 0
  private var shows: [Show] = []
  private var stopLazyLoading: Bool = false
  private let fetchShows: (_ offset: Int, _ limit: Int) async throws -> [Show]

  private let SHOWS_PER_PAGE = 20

  init(
    preloadedShows: [Show]? = nil,
    fetchShows: @escaping (_ offset: Int, _ limit: Int) async throws -> [Show]
  ) {
    if let preloadedShows = preloadedShows, !preloadedShows.isEmpty {
      self.currentOffset = preloadedShows.count
      self.shows = preloadedShows
      self.state = .loaded(self.shows)
    }

    self.fetchShows = fetchShows
  }

  @MainActor
  func updateState(_ newState: State) {
    self.state = newState
  }

  func performInitialLoad() async {
    await self.updateState(.loading)

    do {
      let shows = try await fetchShows(
        currentOffset,
        SHOWS_PER_PAGE
      )

      if shows.isEmpty {
        await self.updateState(.loadedButEmpty)
      }
      else {
        self.currentOffset = self.SHOWS_PER_PAGE
        self.shows = shows
        await self.updateState(.loaded(self.shows))
      }
    }
    catch {
      await self.updateState(.loadingFailed(error))
    }
  }

  func performLazyLoading() async {
    if self.stopLazyLoading {
      return
    }

    do {
      let shows = try await fetchShows(
        currentOffset,
        SHOWS_PER_PAGE
      )

      if shows.count < self.SHOWS_PER_PAGE {
        self.stopLazyLoading = true
      }

      self.currentOffset = self.currentOffset + self.SHOWS_PER_PAGE
      self.shows += shows
      await self.updateState(.loaded(self.shows))
    }
    catch {
      self.stopLazyLoading = true
    }
  }

  func performPullToRefresh() async {
    do {
      let shows = try await fetchShows(
        0,
        SHOWS_PER_PAGE
      )

      if shows.isEmpty {
        await self.updateState(.loadedButEmpty)
      }
      else {
        self.currentOffset = self.SHOWS_PER_PAGE
        self.shows = shows
        await self.updateState(.loaded(self.shows))
      }
    }
    catch {
      await self.updateState(.loadingFailed(error))
    }

    self.stopLazyLoading = false
  }
}

struct FilteredShowsView: View {
  @StateObject public var viewModel: FilteredShowsViewModel

  public let title: String
  public let description: String?
  public let displaySeason: Bool

  var body: some View {
    Group {
      switch self.viewModel.state {
      case .idle:
        Color.clear.onAppear {
          Task {
            await self.viewModel.performInitialLoad()
          }
        }

      case .loading:
        ProgressView()
          .focusable()
          .centeredContentFix()

      case let .loadingFailed(error):
        ContentUnavailableView {
          Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
        } description: {
          Text(error.localizedDescription)
        }
        .focusable()

      case .loadedButEmpty:
        ContentUnavailableView {
          Label("Ничего не нашлось", systemImage: "list.bullet")
        } description: {
          Text("Возможно, это баг")
        }
        .focusable()

      case let .loaded(shows):
        ScrollView([.vertical]) {
          VStack(alignment: .leading, spacing: 40) {
            VStack(alignment: .leading) {
              Text(self.title)
                .font(.title2)

              if let description {
                Text(description)
                  .font(.title3)
                  .foregroundStyle(.secondary)
              }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

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
              ForEach(shows) { show in
                ShowCard(show: show, displaySeason: self.displaySeason)
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
    }
    .refreshable {
      await self.viewModel.performPullToRefresh()
    }
  }
}

// #Preview {
//    NavigationStack {
//        FilteredShowsView()
//    }
// }
