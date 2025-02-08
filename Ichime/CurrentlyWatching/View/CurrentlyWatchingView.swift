import ScraperAPI
import SwiftData
import SwiftUI

@Observable
class CurrentlyWatchingViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded([WatchCardModel])
    case needSubscribe
  }

  private(set) var state: State = .idle

  private let client: ScraperAPI.APIClient
  private let userManager: UserManager
  private var page = 1
  private var shows: [WatchCardModel] = []
  private var stopLazyLoading = false

  init(
    apiClient: ScraperAPI.APIClient = ApplicationDependency.container.resolve(),
    userManager: UserManager = ApplicationDependency.container.resolve()
  ) {
    self.client = apiClient
    self.userManager = userManager
  }

  func performInitialLoading() async {
    if !self.userManager.subscribed {
      return await self.updateState(.needSubscribe)
    }
    await self.updateState(.loading)
    await self.performRefresh()
  }

  func performRefresh() async {
    self.page = 1
    self.shows = []
    self.stopLazyLoading = false

    do {
      let shows = try await client.sendAPIRequest(ScraperAPI.Request.GetNextToWatch(page: self.page))
        .map { WatchCardModel(from: $0) }

      if shows.isEmpty {
        return await self.updateState(.loadedButEmpty)
      }
      else {
        self.shows = shows
        return await self.updateState(.loaded(shows))
      }
    }
    catch {
      await self.updateState(.loadingFailed(error))
    }
  }

  func performLazyLoad() async {
    if self.stopLazyLoading {
      return
    }

    do {
      self.page += 1
      let newShows = try await client.sendAPIRequest(ScraperAPI.Request.GetNextToWatch(page: self.page))

      let newWatchCards = newShows.map { WatchCardModel(from: $0) }

      if newWatchCards.last == self.shows.last {
        self.stopLazyLoading = true
        return
      }

      self.shows += newWatchCards
      await self.updateState(.loaded(self.shows))
    }
    catch {
      self.stopLazyLoading = true
    }
  }

  @MainActor
  private func updateState(_ newState: State) {
    self.state = newState
  }
}

struct CurrentlyWatchingView: View {
  enum Navigation: Hashable {
    case notifications
  }

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

      case .needSubscribe:
        ContentUnavailableView {
          Label("Нужна подписка", systemImage: "person.fill.badge.plus")
        } description: {
          Text("Подпишись чтоб получить все возможности приложения")
        }
        .focusable()

      case let .loadingFailed(error):
        ContentUnavailableView {
          Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
        } description: {
          Text(error.localizedDescription)
        }
        .focusable()

      case .loadedButEmpty:
        ContentUnavailableView {
          Label("Ничего не нашлось", systemImage: "list.bullet")
        } description: {
          Text("Вы еще ничего не добавили в свой список")
        }
        .focusable()

      case let .loaded(shows):
        LoadedCurrentlyWatching(shows: shows) {
          await self.viewModel.performLazyLoad()
        }
      }
    }
    .task {
      switch self.viewModel.state {
      case .loadedButEmpty, .loadingFailed, .loaded, .needSubscribe:
        await self.viewModel.performRefresh()
      case .idle, .loading:
        return
      }
    }
  }
}

struct LoadedCurrentlyWatching: View {
  let shows: [WatchCardModel]
  let loadMore: () async -> Void

  @State private var contextShow: Show? = nil

  private func fetchShowForContext(episode: Int) async {
    let api: Anime365Client = ApplicationDependency.container.resolve()
    do {
      self.contextShow = try await api.getShowByEpisodeId(episodeId: episode)
    }
    catch {
      self.contextShow = nil
    }
  }

  var body: some View {
    ScrollView(.vertical) {
      LazyVGrid(
        columns: [
          GridItem(
            .adaptive(minimum: RawShowCard.RECOMMENDED_MINIMUM_WIDTH),
            spacing: RawShowCard.RECOMMENDED_SPACING,
            alignment: .topLeading
          )
        ],
        spacing: RawShowCard.RECOMMENDED_SPACING
      ) {
        ForEach(self.shows) { show in
          NavigationLink(value: show) {
            WatchCard(data: show)
          }
          .contextMenu(menuItems: {
            Group {
              if let contextShow {
                NavigationLink(destination: ShowView(showId: contextShow.id)) {
                  Text("Открыть")
                }
              }
              else {
                ProgressView()
              }
            }.task {
              await self.fetchShowForContext(episode: show.id)
            }
          })
          .buttonStyle(.borderless)
          .task {
            if show == self.shows.last {
              await self.loadMore()
            }
          }
        }
      }
    }
  }
}

#Preview {
  NavigationStack {
    CurrentlyWatchingView()
      .navigationDestination(for: CurrentlyWatchingView.Navigation.self) { route in
        if route == .notifications {
          NotificationCenterView()
        }
      }
      .navigationDestination(for: WatchCardModel.self) {
        viewEpisodes(show: $0)
      }
  }
}

#Preview("No navigation") {
  CurrentlyWatchingView()
}
