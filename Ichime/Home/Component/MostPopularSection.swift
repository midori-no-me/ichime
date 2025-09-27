import OrderedCollections
import SwiftUI

@Observable @MainActor
private class MostPopularSectionViewModel {
  private static let SHOWS_PER_PAGE = 10

  var shows: OrderedSet<ShowPreviewShikimori> = []

  private var page: Int = 1
  private var stopLazyLoading: Bool = false

  private let showService: ShowService

  init(
    showService: ShowService = ApplicationDependency.container.resolve()
  ) {
    self.showService = showService
  }

  func performInitialLoad(preloadedShows: OrderedSet<ShowPreviewShikimori>) {
    if !self.shows.isEmpty {
      return
    }

    self.shows = preloadedShows
    self.page += 1
  }

  func performLazyLoading() async {
    if self.stopLazyLoading {
      return
    }

    do {
      let shows = try await showService.getMostPopular(
        page: self.page,
        limit: Self.SHOWS_PER_PAGE
      )

      if shows.count < Self.SHOWS_PER_PAGE {
        self.stopLazyLoading = true
      }

      self.page += 1
      self.shows = .init(self.shows.elements + shows)
    }
    catch {
      self.stopLazyLoading = true
    }
  }
}

struct MostPopularSection: View {
  let preloadedShows: OrderedSet<ShowPreviewShikimori>

  @State private var viewModel: MostPopularSectionViewModel = .init()

  var body: some View {
    VStack(alignment: .leading) {
      SectionWithCards(title: "Наиболее популярные") {
        ScrollView(.horizontal) {
          LazyHStack(alignment: .top, spacing: ShowCard.RECOMMENDED_SPACING) {
            ForEach(self.viewModel.shows) { show in
              ShowCardMyAnimeList(show: show, displaySeason: true)
                .containerRelativeFrame(
                  .horizontal,
                  count: ShowCard.RECOMMENDED_COUNT_PER_ROW,
                  span: 1,
                  spacing: ShowCard.RECOMMENDED_SPACING
                )
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
    }
    .onAppear {
      self.viewModel.performInitialLoad(preloadedShows: self.preloadedShows)
    }
  }
}
