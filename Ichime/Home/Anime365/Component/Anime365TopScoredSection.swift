import SwiftUI

@Observable
private class Anime365TopScoredSectionViewModel {
  private static let SHOWS_PER_PAGE = 10

  public var shows: [ShowPreview] = []

  private var offset: Int = 0
  private var stopLazyLoading: Bool = false

  private let showService: ShowService

  init(
    showService: ShowService = ApplicationDependency.container.resolve()
  ) {
    self.showService = showService
  }

  func performInitialLoad(preloadedShows: [ShowPreview]) {
    if !self.shows.isEmpty {
      return
    }

    self.shows = preloadedShows
    self.offset += preloadedShows.count
  }

  func performLazyLoading() async {
    if self.stopLazyLoading {
      return
    }

    do {
      let shows = try await showService.getTopScored(
        offset: self.offset,
        limit: Self.SHOWS_PER_PAGE
      )

      if shows.count < Self.SHOWS_PER_PAGE {
        self.stopLazyLoading = true
      }

      self.offset += shows.count
      self.shows += shows
    }
    catch {
      self.stopLazyLoading = true
    }
  }
}

struct Anime365TopScoredSection: View {
  let preloadedShows: [ShowPreview]

  @State private var viewModel: Anime365TopScoredSectionViewModel = .init()

  var body: some View {
    VStack(alignment: .leading) {
      Section(
        header: Text("С высоким рейтингом")
          .font(.headline)
          .fontWeight(.bold)
          .foregroundStyle(.secondary)
      ) {
        ScrollView(.horizontal) {
          LazyHStack(alignment: .top) {
            ForEach(self.viewModel.shows) { show in
              ShowCard(show: show, displaySeason: true)
                .frame(height: RawShowCard.RECOMMENDED_HEIGHT)
                .containerRelativeFrame(.horizontal, count: 2, span: 1, spacing: 64)
                .task {
                  if show == self.viewModel.shows.last {
                    await self.viewModel.performLazyLoading()
                  }
                }
            }
          }
        }
      }
      .scrollClipDisabled()
    }
    .onAppear {
      self.viewModel.performInitialLoad(preloadedShows: self.preloadedShows)
    }
  }
}
