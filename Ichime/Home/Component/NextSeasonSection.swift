import SwiftUI

@Observable
private class NextSeasonSectionViewModel {
  private static let SHOWS_PER_PAGE = 10

  var shows: [ShowPreviewShikimori] = []

  private var page: Int = 1
  private var stopLazyLoading: Bool = false

  private let showService: ShowService

  init(
    showService: ShowService = ApplicationDependency.container.resolve()
  ) {
    self.showService = showService
  }

  func performInitialLoad(preloadedShows: [ShowPreviewShikimori]) {
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
      let shows = try await showService.getNextSeason(
        page: self.page,
        limit: Self.SHOWS_PER_PAGE
      )

      if shows.count < Self.SHOWS_PER_PAGE {
        self.stopLazyLoading = true
      }

      self.page += 1
      self.shows += shows
    }
    catch {
      self.stopLazyLoading = true
    }
  }
}

struct NextSeasonSection: View {
  let preloadedShows: [ShowPreviewShikimori]

  @State private var viewModel: NextSeasonSectionViewModel = .init()

  var body: some View {
    VStack(alignment: .leading) {
      SectionWithCards(title: "Следующий сезон") {
        ScrollView(.horizontal) {
          LazyHStack(alignment: .top) {
            ForEach(self.viewModel.shows) { show in
              ShowCardShikimori(show: show, displaySeason: false)
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
