import OrderedCollections
import SwiftData
import SwiftUI

@Observable
private class CurrentlyWatchingViewModel {
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
        .onAppear {
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
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 64), count: 2), spacing: 64) {
      ForEach(self.episodes) { episode in
        EpisodeFromCurrentlyWatchingListCard(episode: episode)
          .frame(height: RawShowCard.RECOMMENDED_HEIGHT)
          .task {
            if episode.episodeId == self.episodes.last?.episodeId {
              await self.loadMore()
            }
          }
      }
    }
  }
}
