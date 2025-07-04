import OSLog
import OrderedCollections
import SwiftUI

@Observable
private class OngoingsSectionViewModel {
  private static let SHOWS_PER_PAGE = 10

  var shows: OrderedSet<ShowPreview> = []

  private var offset: Int = 0
  private var stopLazyLoading: Bool = false

  private let showService: ShowService
  private let logger: Logger

  init(
    showService: ShowService = ApplicationDependency.container.resolve(),
    logger: Logger = .init(subsystem: ServiceLocator.applicationId, category: "OngoingsSectionViewModel")
  ) {
    self.showService = showService
    self.logger = logger
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
      let shows = try await showService.getOngoings(
        offset: self.offset,
        limit: Self.SHOWS_PER_PAGE
      )

      if shows.count < Self.SHOWS_PER_PAGE {
        self.logger.debug("Stop lazy loading because next page has less than \(Self.SHOWS_PER_PAGE) items")
        self.stopLazyLoading = true
      }

      self.offset += shows.count
      self.shows = .init(self.shows.elements + shows)
    }
    catch {
      self.logger.debug("Stop lazy loading due to exception: \(error)")
      self.stopLazyLoading = true
    }
  }
}

struct OngoingsSection: View {
  let preloadedShows: OrderedSet<ShowPreview>

  @State private var viewModel: OngoingsSectionViewModel = .init()

  var body: some View {
    SectionWithCards(title: "Онгоинги") {
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
