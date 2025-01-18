import ScraperAPI
import SwiftUI

@Observable
class NotificationCenterViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded([WatchCardModel])
  }

  private(set) var state: State = .idle

  private let client: ScraperAPI.APIClient
  private var page = 1
  private var shows: [WatchCardModel] = []
  private var stopLazyLoading = false

  init(apiClient: ScraperAPI.APIClient = ApplicationDependency.container.resolve()) {
    self.client = apiClient
  }

  func performInitialLoading() async {
    await self.updateState(.loading)
    await self.performRefresh()
  }

  func performRefresh() async {
    self.page = 1
    self.shows = []
    self.stopLazyLoading = false

    do {
      let shows = try await client.sendAPIRequest(ScraperAPI.Request.GetNotifications(page: self.page))
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
      let newShows = try await client.sendAPIRequest(
        ScraperAPI.Request.GetNotifications(page: self.page)
      )

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

struct NotificationCenterView: View {
  @State private var viewModel: NotificationCenterViewModel = .init()
  @StateObject private var notificationCounter: NotificationCounterWatcher = .init()

  var body: some View {
    Group {
      switch self.viewModel.state {
      case .idle:
        Color.clear.onAppear {
          Task {
            await self.viewModel.performInitialLoading()
            await self.notificationCounter.checkCounter()
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
          Label("Пока еще не было уведомлений", systemImage: "list.bullet")
        } description: {
          Text("Как только вы добавите аниме в свой список, начнут приходить уведомления")
        }
        .focusable()

      case let .loaded(shows):
        LoadedNotificationCenter(shows: shows) {
          await self.viewModel.performLazyLoad()
        }
      }
    }
    .task {
      switch self.viewModel.state {
      case .loadedButEmpty, .loaded, .loadingFailed:
        await self.viewModel.performRefresh()
      case .idle, .loading:
        return
      }
    }
    .refreshable {
      await self.viewModel.performRefresh()
    }
  }
}

struct LoadedNotificationCenter: View {
  let shows: [WatchCardModel]
  let loadMore: () async -> Void

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
    NotificationCenterView()
  }
}
