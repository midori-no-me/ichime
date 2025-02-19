import SwiftData
import SwiftUI

@Observable
private class CurrentlyWatchingViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded([EpisodeFromCurrentlyWatchingList])
  }

  private(set) var state: State = .idle

  private let currentlyWatchingService: CurrentlyWatchingService

  private var episodes: [EpisodeFromCurrentlyWatchingList] = []
  private var currentPage: Int = 1
  private var stopLazyLoading: Bool = false

  init(
    currentlyWatchingService: CurrentlyWatchingService = ApplicationDependency.container.resolve()
  ) {
    self.currentlyWatchingService = currentlyWatchingService
  }

  func performInitialLoading() async {
    print("performInitialLoading")

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
    print("performLazyLoading")

    if self.stopLazyLoading {
      return
    }

    do {
      let episodes = try await currentlyWatchingService.getEpisodesToWatch(page: self.currentPage)

      if episodes.last?.episodeId == self.episodes.last?.episodeId {
        self.stopLazyLoading = true
        return
      }

      self.stopLazyLoading = false
      self.currentPage += 1
      self.episodes += episodes
      self.state = .loaded(self.episodes)
    }
    catch {
      self.stopLazyLoading = true
    }
  }

  func performRefresh() async {
    print("performRefresh")

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
        }
        .focusable()

      case .loadedButEmpty:
        ContentUnavailableView {
          Label("Пусто", systemImage: "list.bullet")
        } description: {
          Text("Пока что нет серий, доступных к просмотру")
        }
        .focusable()

      case let .loaded(episodes):
        ScrollView([.vertical]) {
          VStack(alignment: .leading) {
            Section(
              header: Text("Серии к просмотру")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
            ) {
              EpisodesGrid(
                episodes: episodes,
                loadMore: { await self.viewModel.performLazyLoading() }
              )
            }
          }
        }
        .task {
          await self.viewModel.performRefresh()
        }
      }
    }
  }
}

private struct EpisodesGrid: View {
  let episodes: [EpisodeFromCurrentlyWatchingList]
  let loadMore: () async -> Void

  var body: some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 64), count: 2), spacing: 64) {
      ForEach(self.episodes, id: \.episodeId) { episode in
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
