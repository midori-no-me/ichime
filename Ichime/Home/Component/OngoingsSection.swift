import OSLog
import OrderedCollections
import SwiftUI

@Observable @MainActor
private final class OngoingsSectionViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded(shows: OrderedSet<ShowPreview>, hasMore: Bool)
  }

  private static let SHOWS_PER_PAGE = 10

  private(set) var state: State = .idle

  private let showService: ShowService
  private let logger: Logger

  init(
    showService: ShowService = ApplicationDependency.container.resolve(),
    logger: Logger = .init(subsystem: ServiceLocator.applicationId, category: "OngoingsSectionViewModel")
  ) {
    self.showService = showService
    self.logger = logger
  }

  func performInitialLoading() async {
    self.updateState(.loading)

    do {
      let shows = try await showService.getOngoings(
        offset: 0,
        limit: Self.SHOWS_PER_PAGE
      )

      if shows.isEmpty {
        self.updateState(.loadedButEmpty)
      }
      else {
        self.updateState(
          .loaded(
            shows: shows,
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
    guard case let .loaded(alreadyLoadedShows, hasMore) = state else {
      return
    }

    if !hasMore {
      return
    }

    do {
      let shows = try await showService.getOngoings(
        offset: alreadyLoadedShows.count,
        limit: Self.SHOWS_PER_PAGE
      )

      self.updateState(
        .loaded(
          shows: .init(alreadyLoadedShows.elements + shows),
          hasMore: shows.count == Self.SHOWS_PER_PAGE
        )
      )
    }
    catch {
      self.logger.debug("Stop lazy loading due to exception: \(error)")
    }
  }

  private func updateState(_ state: State) {
    withAnimation(.default.speed(0.5)) {
      self.state = state
    }
  }
}

struct OngoingsSection: View {
  @State private var viewModel: OngoingsSectionViewModel = .init()

  var body: some View {
    SectionWithCards(title: "Онгоинги") {
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

        case let .loaded(shows, _):
          ShowCardHStack(
            cards: shows.elements,
            loadMore: { await self.viewModel.performLazyLoading() }
          ) { show in
            ShowCardAnime365(
              show: show,
              displaySeason: !Self.isCurrentSeason(show: show),
            )
          }
        }
      }
      .focusSection()
      .scrollClipDisabled()
    }
  }

  private static func isCurrentSeason(show: ShowPreview) -> Bool {
    let currentAiringSeason = ShowSeasonService().getRelativeSeason(shift: 0)

    guard let airingSeason = show.airingSeason else {
      return false
    }

    return currentAiringSeason == airingSeason
  }
}
