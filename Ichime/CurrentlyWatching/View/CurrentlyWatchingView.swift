import Anime365Kit
import OrderedCollections
import SwiftData
import SwiftUI

@Observable @MainActor
private final class CurrentlyWatchingViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded(OrderedSet<EpisodeFromCurrentlyWatchingList>)
  }

  private var _state: State = .idle
  private let currentlyWatchingService: CurrentlyWatchingService

  private var episodes: OrderedSet<EpisodeFromCurrentlyWatchingList> = []
  private var currentPage: Int = 1
  private var stopLazyLoading: Bool = false

  private(set) var state: State {
    get {
      self._state
    }
    set {
      withAnimation {
        self._state = newValue
      }
    }
  }

  init(
    currentlyWatchingService: CurrentlyWatchingService = ApplicationDependency.container.resolve()
  ) {
    self.currentlyWatchingService = currentlyWatchingService
  }

  func performInitialLoading() async {
    self.state = .loading

    do {
      let episodes = try await currentlyWatchingService.getEpisodesToWatch(page: self.currentPage)

      if episodes.isEmpty {
        self.state = .loadedButEmpty
      }
      else {
        self.stopLazyLoading = false
        self.currentPage = 1
        self.episodes = episodes
        self.state = .loaded(self.episodes)
      }
    }
    catch {
      self.state = .loadingFailed(error)
    }
  }

  func performLazyLoading() async {
    if self.stopLazyLoading {
      return
    }

    do {
      self.currentPage += 1

      let episodes = try await currentlyWatchingService.getEpisodesToWatch(page: self.currentPage)

      if episodes.last?.episodeId == self.episodes.last?.episodeId {
        self.stopLazyLoading = true
        return
      }

      self.stopLazyLoading = false
      self.episodes = .init(self.episodes.elements + episodes)
      self.state = .loaded(self.episodes)
    }
    catch {
      self.stopLazyLoading = true
    }
  }

  func performRefresh() async {
    self.currentPage = 1
    self.episodes = []
    self.stopLazyLoading = false

    do {
      let episodes = try await currentlyWatchingService.getEpisodesToWatch(page: self.currentPage)

      if episodes.isEmpty {
        self.state = .loadedButEmpty
      }
      else {
        self.episodes = episodes
        self.state = .loaded(self.episodes)
      }
    }
    catch {
      self.state = .loadingFailed(error)
    }
  }
}

struct CurrentlyWatchingView: View {
  @State private var viewModel: CurrentlyWatchingViewModel = .init()

  var body: some View {
    Group {
      switch self.viewModel.state {
      case .idle:
        Color.clear.onAppear {
          Task {
            await self.viewModel.performInitialLoading()
          }
        }
      case .loading:
        ProgressView()
          .focusable()
          .centeredContentFix()

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
          ContentUnavailableView {
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
          .centeredContentFix()
        }

      case .loadedButEmpty:
        ContentUnavailableView {
          Label("Пусто", systemImage: "list.bullet")
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
        .centeredContentFix()

      case let .loaded(episodes):
        ScrollView(.vertical) {
          SectionWithCards(title: "Серии к просмотру") {
            EpisodesGrid(
              episodes: episodes,
              loadMore: { await self.viewModel.performLazyLoading() }
            )
          }
        }
        .refreshOnAppear {
          Task {
            await self.viewModel.performRefresh()
          }
        }
      }
    }
  }
}

private struct EpisodesGrid: View {
  let episodes: OrderedSet<EpisodeFromCurrentlyWatchingList>
  let loadMore: () async -> Void

  var body: some View {
    LazyVGrid(
      columns: Array(
        repeating: GridItem(.flexible(), spacing: ShowCard.RECOMMENDED_SPACING),
        count: ShowCard.RECOMMENDED_COUNT_PER_ROW
      ),
      spacing: ShowCard.RECOMMENDED_SPACING
    ) {
      ForEach(self.episodes) { episode in
        EpisodeFromCurrentlyWatchingListCard(episode: episode)
          .task {
            if episode.episodeId == self.episodes.last?.episodeId {
              await self.loadMore()
            }
          }
      }
    }
  }
}
