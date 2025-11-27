import OSLog
import OrderedCollections
import SwiftUI

@Observable @MainActor
private final class MostPopularSectionViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded(shows: OrderedSet<ShowPreviewShikimori>, page: Int, hasMore: Bool)
  }

  private static let SHOWS_PER_PAGE = 10

  private(set) var state: State = .idle

  private let showService: ShowService
  private let logger: Logger

  init(
    showService: ShowService = ApplicationDependency.container.resolve(),
    logger: Logger = .init(subsystem: ServiceLocator.applicationId, category: "MostPopularSectionViewModel")
  ) {
    self.showService = showService
    self.logger = logger
  }

  func performInitialLoading() async {
    self.updateState(.loading)

    do {
      let shows = try await showService.getMostPopular(
        page: 1,
        limit: Self.SHOWS_PER_PAGE
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

  func performLazyLoading() async {
    guard case let .loaded(alreadyLoadedShows, page, hasMore) = state else {
      return
    }

    if !hasMore {
      return
    }

    do {
      let shows = try await showService.getMostPopular(
        page: page + 1,
        limit: Self.SHOWS_PER_PAGE
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

  private func updateState(_ state: State) {
    withAnimation(.easeInOut(duration: 0.5)) {
      self.state = state
    }
  }
}

struct MostPopularSection: View {
  @State private var viewModel: MostPopularSectionViewModel = .init()

  var body: some View {
    SectionWithCards(title: "Наиболее популярные") {
      ScrollView(.horizontal) {
        switch self.viewModel.state {
        case .idle:
          ShowCardHStackInteractiveSkeleton()
            .onAppear {
              Task {
                await self.viewModel.performInitialLoading()
              }
            }

        case .loading:
          ShowCardHStackInteractiveSkeleton()

        case let .loadingFailed(error):
          ShowCardHStackContentUnavailable {
            Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
          } description: {
            Text(error.localizedDescription)
          } actions: {
            Button(action: {
              Task {
                await self.viewModel.performInitialLoading()
              }
            }) {
              Text("Обновить")
            }
          }

        case .loadedButEmpty:
          ShowCardHStackContentUnavailable {
            Label("Пусто", systemImage: "rectangle.portrait.on.rectangle.portrait.angled")
          } description: {
            Text("Ничего не нашлось")
          } actions: {
            Button(action: {
              Task {
                await self.viewModel.performInitialLoading()
              }
            }) {
              Text("Обновить")
            }
          }

        case let .loaded(shows, _, _):
          ShowCardHStack(
            cards: shows.elements,
            loadMore: { await self.viewModel.performLazyLoading() }
          ) { show in
            ShowCardMyAnimeList(
              show: show,
              displaySeason: !Self.isCurrentSeason(show: show),
            )
          }
        }
      }
      .scrollClipDisabled()
      .scrollIndicators(.hidden)
    }
  }

  private static func isCurrentSeason(show: ShowPreviewShikimori) -> Bool {
    let currentAiringSeason = ShowSeasonService().getRelativeSeason(shift: 0)

    guard let airingSeason = show.airingSeason else {
      return false
    }

    return currentAiringSeason == airingSeason
  }
}
