//
//  NotificationCenterView.swift
//  ichime
//
//  Created by p.flaks on 20.01.2024.
//

import ScraperAPI
import SwiftUI

@Observable
class NotificationCenterViewModel {
    private let client: ScraperAPI.APIClient
    init(apiClient: ScraperAPI.APIClient = ApplicationDependency.container.resolve()) {
        client = apiClient
    }

    enum State {
        case idle
        case loading
        case loadingFailed(Error)
        case loadedButEmpty
        case loaded([WatchCardModel])
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
        await updateState(.loading)
        await performRefresh()
    }

    func performRefresh() async {
        page = 1
        shows = []
        stopLazyLoading = false

        do {
            let shows = try await client.sendAPIRequest(ScraperAPI.Request.GetNotifications(page: page))
                .map { WatchCardModel(from: $0) }

            if shows.isEmpty {
                return await updateState(.loadedButEmpty)
            } else {
                self.shows = shows
                return await updateState(.loaded(shows))
            }
        } catch {
            await updateState(.loadingFailed(error))
        }
    }

    func performLazyLoad() async {
        if stopLazyLoading {
            return
        }

        do {
            page += 1
            let newShows = try await client.sendAPIRequest(ScraperAPI.Request.GetNotifications(page: page))

            let newWatchCards = newShows.map { WatchCardModel(from: $0) }

            if newWatchCards.last == shows.last {
                stopLazyLoading = true
                return
            }

            shows += newWatchCards
            await updateState(.loaded(shows))
        } catch {
            stopLazyLoading = true
        }
    }
}

struct NotificationCenterView: View {
    @State private var viewModel: NotificationCenterViewModel = .init()
    @StateObject private var notificationCounter: NotificationCounterWatcher = .init()

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                Color.clear.onAppear {
                    Task {
                        await viewModel.performInitialLoading()
                        await notificationCounter.checkCounter()
                    }
                }
            case .loading:
                ProgressView()
                #if os(tvOS)
                    .focusable()
                #endif

            case let .loadingFailed(error):
                ContentUnavailableView {
                    Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error.localizedDescription)
                }
                #if !os(tvOS)
                .textSelection(.enabled)
                #endif
            case .loadedButEmpty:
                ContentUnavailableView {
                    Label("Пока еще не было уведомлений", systemImage: "list.bullet")
                } description: {
                    Text("Как только вы добавите аниме в свой список, начнут приходить уведомления")
                }
            case let .loaded(shows):
                LoadedNotificationCenter(shows: shows) {
                    await viewModel.performLazyLoad()
                }
            }
        }
        .task {
            switch viewModel.state {
            case .loadedButEmpty, .loaded, .loadingFailed:
                await viewModel.performRefresh()
            case .idle, .loading:
                return
            }
        }
        .refreshable {
            await viewModel.performRefresh()
        }
        #if !os(tvOS)
        .toolbar {
            ProfileButton()
        }
        .navigationTitle("Уведомления")
        #endif
    }
}

struct LoadedNotificationCenter: View {
    let shows: [WatchCardModel]
    let loadMore: () async -> Void

    var body: some View {
        #if os(tvOS)
            ScrollView(.vertical) {
                LazyVGrid(columns: [
                    GridItem(
                        .adaptive(minimum: RawShowCard.RECOMMENDED_MINIMUM_WIDTH),
                        spacing: RawShowCard.RECOMMENDED_SPACING,
                        alignment: .topLeading
                    ),
                ], spacing: RawShowCard.RECOMMENDED_SPACING) {
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
            .scrollClipDisabled(true)
        #else
            List {
                Section {
                    ForEach(shows) { show in
                        NavigationLink(value: show) {
                            WatchCard(data: show)
                        }
                        .task {
                            if show == self.shows.last {
                                await self.loadMore()
                            }
                        }
                    }
                } header: {
                    Text("Последние уведомления")
                }
            }
            .listStyle(.plain)
        #endif
    }
}

#Preview {
    NavigationStack {
        NotificationCenterView()
    }
}
