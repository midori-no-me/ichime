//
//  MyListsView.swift
//  ichime
//
//  Created by p.flaks on 20.01.2024.
//

import ScraperAPI
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
            let newShows = try await client.sendAPIRequest(ScraperAPI.Request.GetNextToWatch(page: page))

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

struct CurrentlyWatchingView: View {
    @State private var viewModel: CurrentlyWatchingViewModel = .init()
    @StateObject private var notificationCounter: NotificationCounterWatcher = .init()

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
            case .needSubscribe:
                ContentUnavailableView {
                    Label("Нужна подписка", systemImage: "person.fill.badge.plus")
                } description: {
                    Text("Подпишись чтоб получить все возможности приложения")
                }
                #if !os(tvOS)
                .textSelection(.enabled)
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
                    Label("Ничего не нашлось", systemImage: "list.bullet")
                } description: {
                    Text("Вы еще ничего не добавили в свой список")
                }
            case let .loaded(shows):
                LoadedCurrentlyWatching(shows: shows, counter: notificationCounter.counter) {
                    await viewModel.performLazyLoad()
                }.refreshable {
                    await viewModel.performRefresh()
                    await notificationCounter.checkCounter()
                }
            }
        }
        #if !os(tvOS)
        .toolbar {
            ProfileButton()
        }
        .navigationTitle("Я смотрю")
        #endif
    }

    enum SubRoute: Hashable {
        case notifications
    }
}

struct LoadedCurrentlyWatching: View {
    let shows: [WatchCardModel]
    let counter: Int
    let loadMore: () async -> Void

    var body: some View {
        List {
            #if os(iOS)
                if UIDevice.current.userInterfaceIdiom == .phone {
                    Section {
                        NavigationLink(value: CurrentlyWatchingView.SubRoute.notifications) {
                            Label("Уведомления", systemImage: "bell")
                                .badge(counter)
                        }
                    }
                }
            #endif

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
                #if !os(tvOS)
                    Text("Серии к просмотру")
                #endif
            }
        }
        .listStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        CurrentlyWatchingView()
            .navigationDestination(for: CurrentlyWatchingView.SubRoute.self) { route in
                if route == .notifications {
                    NotificationCenterView()
                }
            }
            .navigationDestination(for: WatchCardModel.self) {
                viewShow(show: $0)
            }
    }
}

#Preview("No navigation") {
    CurrentlyWatchingView()
}
