import OrderedCollections
import SwiftUI

@Observable
private class RandomSectionViewModel {
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
      let shows = try await showService.getRandom(
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

struct RandomSection: View {
  let preloadedShows: OrderedSet<ShowPreviewShikimori>

  @State private var viewModel: RandomSectionViewModel = .init()

  var body: some View {
    VStack(alignment: .leading) {
      SectionWithCards(title: "Случайные") {
        ScrollView(.horizontal) {
          LazyHStack(alignment: .top) {
            ForEach(self.viewModel.shows) { show in
              ShowCardShikimori(show: show, displaySeason: true)
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
    }
    .onAppear {
      self.viewModel.performInitialLoad(preloadedShows: self.preloadedShows)
    }
  }
}
