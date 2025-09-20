import SwiftUI

@Observable
private class FilteredShowsViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded([ShowPreview])
  }

  private static let SHOWS_PER_PAGE = 20

  private var _state: State = .idle
  private var shows: [ShowPreview] = []
  private var offset: Int = 0
  private var stopLazyLoading: Bool = false

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

  func performInitialLoading(
    fetchShows: (_ offset: Int, _ limit: Int) async throws -> [ShowPreview]
  ) async {
    self.state = .loading

    do {
      let shows = try await fetchShows(self.offset, Self.SHOWS_PER_PAGE)

      if shows.isEmpty {
        self.state = .loadedButEmpty
      }
      else {
        self.stopLazyLoading = false
        self.offset += Self.SHOWS_PER_PAGE
        self.shows += shows
        self.state = .loaded(self.shows)
      }
    }
    catch {
      self.state = .loadingFailed(error)
    }
  }

  func performLazyLoading(
    fetchShows: (_ offset: Int, _ limit: Int) async throws -> [ShowPreview]
  ) async {
    if self.stopLazyLoading {
      return
    }

    do {
      let shows = try await fetchShows(self.offset, Self.SHOWS_PER_PAGE)

      if shows.last?.id == self.shows.last?.id {
        self.stopLazyLoading = true
        return
      }

      self.stopLazyLoading = false
      self.offset += Self.SHOWS_PER_PAGE
      self.shows += shows
      self.state = .loaded(self.shows)
    }
    catch {
      self.stopLazyLoading = true
    }
  }
}

struct FilteredShowsView: View {
  let title: String
  let displaySeason: Bool
  let fetchShows: (_ offset: Int, _ limit: Int) async throws -> [ShowPreview]

  @State private var viewModel: FilteredShowsViewModel = .init()

  var body: some View {
    switch self.viewModel.state {
    case .idle:
      Color.clear.onAppear {
        Task {
          await self.viewModel.performInitialLoading(fetchShows: self.fetchShows)
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
      } actions: {
        Button(action: {
          Task {
            await self.viewModel.performInitialLoading(fetchShows: self.fetchShows)
          }
        }) {
          Text("Обновить")
        }
      }
      .centeredContentFix()

    case .loadedButEmpty:
      ContentUnavailableView {
        Label("Ничего не нашлось", systemImage: "list.bullet")
      } description: {
        Text("Возможно, это баг")
      } actions: {
        Button(action: {
          Task {
            await self.viewModel.performInitialLoading(fetchShows: self.fetchShows)
          }
        }) {
          Text("Обновить")
        }
      }
      .centeredContentFix()

    case let .loaded(shows):
      ScrollView(.vertical) {
        SectionWithCards(title: self.title) {
          LazyVGrid(
            columns: Array(
              repeating: GridItem(.flexible(), spacing: ShowCard.RECOMMENDED_SPACING),
              count: ShowCard.RECOMMENDED_COUNT_PER_ROW
            ),
            spacing: ShowCard.RECOMMENDED_SPACING
          ) {
            ForEach(shows) { show in
              ShowCardAnime365(show: show, displaySeason: self.displaySeason)
                .task {
                  if show == shows.last {
                    await self.viewModel.performLazyLoading(fetchShows: self.fetchShows)
                  }
                }
            }
          }
        }
      }
    }
  }
}
