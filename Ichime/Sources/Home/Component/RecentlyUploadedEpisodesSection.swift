import OSLog
import OrderedCollections
import SwiftUI

@Observable @MainActor
private final class RecentlyUploadedEpisodesSectionViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded(shows: OrderedSet<RecentlyUploadedEpisode>, page: Int, hasMore: Bool)
  }

  private(set) var state: State = .idle

  private let episodeService: EpisodeService
  private let logger: Logger

  init(
    episodeService: EpisodeService = ApplicationDependency.container.resolve(),
    logger: Logger = .init(
      subsystem: ServiceLocator.applicationId,
      category: "RecentlyUploadedEpisodesSectionViewModel"
    )
  ) {
    self.episodeService = episodeService
    self.logger = logger
  }

  func performInitialLoading() async {
    self.updateState(.loading)

    do {
      let episodes = try await episodeService.getRecentEpisodes(
        page: 1,
      )

      if episodes.isEmpty {
        self.updateState(.loadedButEmpty)
      }
      else {
        self.updateState(
          .loaded(
            shows: episodes,
            page: 1,
            hasMore: true
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
      let episodes = try await episodeService.getRecentEpisodes(
        page: page + 1,
      )

      self.updateState(
        .loaded(
          shows: .init(alreadyLoadedEpisodes.elements + episodes),
          page: page + 1,
          hasMore: episodes.last?.episodeId == alreadyLoadedEpisodes.last?.episodeId
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

struct RecentlyUploadedEpisodesSection: View {
  @State private var viewModel: RecentlyUploadedEpisodesSectionViewModel = .init()

  @AppStorage(Anime365BaseURL.UserDefaultsKey.BASE_URL, store: Anime365BaseURL.getUserDefaults()) private
    var anime365BaseURL: URL = Anime365BaseURL.DEFAULT_BASE_URL

  var body: some View {
    SectionWithCards(title: "Новые серии") {
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

        case let .loaded(episodes, _, _):
          ShowCardHStack(
            cards: episodes.elements,
            loadMore: {
              await self.viewModel.performLazyLoading()
            }
          ) { episode in
            RecentlyUploadedEpisodeCard(episode: episode)
          }
        }
      }
      .scrollClipDisabled()
    }
    .onChange(of: self.anime365BaseURL) {
      Task {
        await self.viewModel.performInitialLoading()
      }
    }
  }
}
