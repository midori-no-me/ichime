import OrderedCollections
import SwiftUI

@Observable
private class TopScoredSectionViewModel {
  private static let SHOWS_PER_PAGE = 10

  var shows: OrderedSet<ShowPreview> = []

  private var offset: Int = 0
  private var stopLazyLoading: Bool = false

  private let showService: ShowService

  init(
    showService: ShowService = ApplicationDependency.container.resolve()
  ) {
    self.showService = showService
  }

  func performInitialLoad(preloadedShows: OrderedSet<ShowPreview>) {
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
      self.shows = .init(self.shows.elements + shows)
    }
    catch {
      self.stopLazyLoading = true
    }
  }
}

struct TopScoredSection: View {
  let preloadedShows: OrderedSet<ShowPreview>

  @State private var viewModel: TopScoredSectionViewModel = .init()

  var body: some View {
    SectionWithCards(title: "С высоким рейтингом") {
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
      .scrollClipDisabled()
    }
    .onAppear {
      self.viewModel.performInitialLoad(preloadedShows: self.preloadedShows)
    }
  }
}
