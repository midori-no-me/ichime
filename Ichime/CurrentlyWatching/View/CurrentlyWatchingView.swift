//
//  MyListsView.swift
//  ichime
//
//  Created by p.flaks on 20.01.2024.
//

import ScraperAPI
import SwiftData
import SwiftUI

@Observable
class CurrentlyWatchingViewModel {
  private let client: ScraperAPI.APIClient
  private let userManager: UserManager
  init(
    apiClient: ScraperAPI.APIClient = ApplicationDependency.container.resolve(),
    userManager: UserManager = ApplicationDependency.container.resolve()
  ) {
    client = apiClient
    self.userManager = userManager
  }

  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded([WatchCardModel])
    case needSubscribe
  }

  private(set) var state = State.idle
  private var page = 1
  private var shows: [WatchCardModel] = []
  private var stopLazyLoading = false

  @MainActor
  private func updateState(_ newState: State) {
    state = newState
  }

  func performInitialLoading() async {
    if !userManager.subscribed {
      return await updateState(.needSubscribe)
    }
    await updateState(.loading)
    await performRefresh()
  }

  func performRefresh() async {
    page = 1
    shows = []
    stopLazyLoading = false

    do {
      let shows = try await client.sendAPIRequest(ScraperAPI.Request.GetNextToWatch(page: page))
        .map { WatchCardModel(from: $0) }

      if shows.isEmpty {
        return await updateState(.loadedButEmpty)
      }
      else {
        self.shows = shows
        return await updateState(.loaded(shows))
      }
    }
    catch {
      await updateState(.loadingFailed(error))
    }
  }

  func performLazyLoad() async {
    if stopLazyLoading {
      return
    }

    do {
      page += 1
      let newShows = try await client.sendAPIRequest(ScraperAPI.Request.GetNextToWatch(page: page))

      let newWatchCards = newShows.map { WatchCardModel(from: $0) }

      if newWatchCards.last == shows.last {
        stopLazyLoading = true
        return
      }

      shows += newWatchCards
      await updateState(.loaded(shows))
    }
    catch {
      stopLazyLoading = true
    }
  }
}

struct CurrentlyWatchingView: View {
  @State private var viewModel: CurrentlyWatchingViewModel = .init()

  var body: some View {
    Group {
      switch viewModel.state {
      case .idle:
        Color.clear.onAppear {
          Task {
            await viewModel.performInitialLoading()
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

      case let .loadingFailed(error):
        ContentUnavailableView {
          Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
        } description: {
          Text(error.localizedDescription)
        }

      case .loadedButEmpty:
        ContentUnavailableView {
          Label("Ничего не нашлось", systemImage: "list.bullet")
        } description: {
          Text("Вы еще ничего не добавили в свой список")
        }
      case let .loaded(shows):
        LoadedCurrentlyWatching(shows: shows) {
          await viewModel.performLazyLoad()
        }
      }
    }
    .task {
      switch viewModel.state {
      case .loadedButEmpty, .loadingFailed, .loaded, .needSubscribe:
        await viewModel.performRefresh()
      case .idle, .loading:
        return
      }
    }
    .refreshable {
      await viewModel.performRefresh()
    }
  }

  enum Navigation: Hashable {
    case notifications
  }
}

struct LoadedCurrentlyWatching: View {
  let shows: [WatchCardModel]
  let loadMore: () async -> Void

  @State private var contextShow: Show? = nil

  private func fetchShowForContext(episode: Int) async {
    let api: Anime365Client = ApplicationDependency.container.resolve()
    do {
      contextShow = try await api.getShowByEpisodeId(episodeId: episode)
    }
    catch {
      contextShow = nil
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
              await fetchShowForContext(episode: show.id)
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
