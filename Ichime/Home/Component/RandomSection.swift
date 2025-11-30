import OSLog
import OrderedCollections
import SwiftUI

@Observable @MainActor
private final class RandomSectionViewModel {
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
    logger: Logger = .init(subsystem: ServiceLocator.applicationId, category: "RandomSectionViewModel")
  ) {
    self.showService = showService
    self.logger = logger
  }

  func performInitialLoading(adultOnly: Bool) async {
    self.updateState(.loading)

    do {
      let shows = try await showService.getRandom(
        page: 1,
        limit: Self.SHOWS_PER_PAGE,
        adultOnly: adultOnly,
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

  func performLazyLoading(adultOnly: Bool) async {
    guard case let .loaded(alreadyLoadedShows, page, hasMore) = state else {
      return
    }

    if !hasMore {
      return
    }

    do {
      let shows = try await showService.getRandom(
        page: page + 1,
        limit: Self.SHOWS_PER_PAGE,
        adultOnly: adultOnly,
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

struct RandomSection: View {
  @State private var viewModel: RandomSectionViewModel = .init()

  @AppStorage(Anime365BaseURL.UserDefaultsKey.BASE_URL, store: Anime365BaseURL.getUserDefaults()) private
    var anime365BaseURL: URL = Anime365BaseURL.DEFAULT_BASE_URL

  var body: some View {
    SectionWithCards(title: "Случайные") {
      ScrollView(.horizontal) {
        switch self.viewModel.state {
        case .idle:
          ShowCardHStackInteractiveSkeleton()
            .onAppear {
              Task {
                await self.viewModel.performInitialLoading(
                  adultOnly: Anime365BaseURL.isAdultDomain(self.anime365BaseURL)
                )
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
                await self.viewModel.performInitialLoading(
                  adultOnly: Anime365BaseURL.isAdultDomain(self.anime365BaseURL)
                )
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
                await self.viewModel.performInitialLoading(
                  adultOnly: Anime365BaseURL.isAdultDomain(self.anime365BaseURL)
                )
              }
            }) {
              Text("Обновить")
            }
          }

        case let .loaded(shows, _, _):
          ShowCardHStack(
            cards: shows.elements,
            loadMore: {
              await self.viewModel.performLazyLoading(
                adultOnly: Anime365BaseURL.isAdultDomain(self.anime365BaseURL)
              )
            }
          ) { show in
            ShowCardMyAnimeList(
              show: show,
              displaySeason: true,
              hiddenKindChips: Anime365BaseURL.isAdultDomain(self.anime365BaseURL) ? .init([.ova]) : .init([.tv]),
            )
          }
        }
      }
      .scrollClipDisabled()
      .scrollIndicators(.hidden)
    }
  }
}
