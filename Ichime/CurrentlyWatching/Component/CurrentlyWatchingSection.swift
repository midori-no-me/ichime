import Anime365Kit
import OSLog
import OrderedCollections
import SwiftUI

@Observable @MainActor
private final class CurrentlyWatchingSectionViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded(episodes: OrderedSet<EpisodeFromCurrentlyWatchingList>, page: Int, hasMore: Bool)
  }

  private(set) var state: State = .idle

  private let currentlyWatchingService: CurrentlyWatchingService
  private let logger: Logger

  init(
    currentlyWatchingService: CurrentlyWatchingService = ApplicationDependency.container.resolve(),
    logger: Logger = .init(subsystem: ServiceLocator.applicationId, category: "CurrentlyWatchingSectionViewModel")
  ) {
    self.currentlyWatchingService = currentlyWatchingService
    self.logger = logger
  }

  func performInitialLoading() async {
    self.updateState(.loading)

    do {
      let episodes = try await currentlyWatchingService.getEpisodesToWatch(page: 1)

      if episodes.isEmpty {
        self.updateState(.loadedButEmpty)
      }
      else {
        self.updateState(
          .loaded(
            episodes: episodes,
            page: 1,
            hasMore: true,
          )
        )
      }
    }
    catch {
      self.updateState(.loadingFailed(error))
    }
  }

  func performLazyLoading() async {
    guard case let .loaded(alreadyLoadedEpisodes, page, hasMore) = state else {
      return
    }

    if !hasMore {
      return
    }

    do {
      let episodes = try await currentlyWatchingService.getEpisodesToWatch(page: page + 1)

      self.updateState(
        .loaded(
          episodes: .init(alreadyLoadedEpisodes.elements + episodes),
          page: page + 1,
          hasMore: episodes.last?.episodeId == alreadyLoadedEpisodes.last?.episodeId,
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

struct CurrentlyWatchingSection: View {
  @State private var viewModel: CurrentlyWatchingSectionViewModel = .init()

  var body: some View {
    SectionWithCards(title: "Серии к просмотру") {
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
          if case Anime365Kit.WebClientError.authenticationRequired = error {
            AuthenticationRequiredContentUnavailableView(onSuccessfulAuth: {
              Task {
                await self.viewModel.performInitialLoading()
              }
            })
            .centeredContentFix()
          }
          else {
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
          }

        case .loadedButEmpty:
          ShowCardHStackContentUnavailable {
            Label("Пусто", systemImage: "rectangle.portrait.on.rectangle.portrait.angled")
          } description: {
            Text("Пока что нет серий, доступных к просмотру")
          } actions: {
            Button(action: {
              Task {
                await self.viewModel.performInitialLoading()
              }
            }) {
              Text("Обновить")
            }
          }

        case let .loaded(episodes, _, _):
          ShowCardHStack(
            cards: episodes.elements,
            loadMore: {
              await self.viewModel.performLazyLoading()
            }
          ) { episode in
            EpisodeFromCurrentlyWatchingListCard(episode: episode)
          }
          .refreshOnAppear {
            Task {
              await self.viewModel.performInitialLoading()
            }
          }
        }
      }
      .scrollClipDisabled()
    }
  }
}
