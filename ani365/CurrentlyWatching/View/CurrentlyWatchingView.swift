//
//  MyListsView.swift
//  ani365
//
//  Created by p.flaks on 20.01.2024.
//

import ScraperAPI
import SwiftUI

class CurrentlyWatchingViewModel: ObservableObject {
    private let client: ScraperClient
    init(apiClient: ScraperClient) {
        print("create")
        client = apiClient
    }

    enum State {
        case idle
        case loading
        case loadingFailed(Error)
        case loadedButEmpty
        case loaded([WatchCardModel])
        case needAuth
    }

    @Published private(set) var state = State.idle
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
            let shows = try await client.api.sendAPIRequest(ScraperAPI.Request.GetNextToWatch(page: page))
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
            let newShows = try await client.api.sendAPIRequest(ScraperAPI.Request.GetNextToWatch(page: page))

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
    @ObservedObject var viewModel: CurrentlyWatchingViewModel
    @EnvironmentObject var client: ScraperClient

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
            case let .loadingFailed(error):
                ContentUnavailableView {
                    Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error.localizedDescription)
                }
                .textSelection(.enabled)
            case .needAuth:
                ContentUnavailableView {
                    Label("Нужна авторизация", systemImage: "faceid")
                }
                .textSelection(.enabled)
            case .loadedButEmpty:
                ContentUnavailableView {
                    Label("Ничего не нашлось", systemImage: "list.bullet")
                } description: {
                    Text("Вы еще ничего не добавили в свой список")
                }
            case let .loaded(shows):
                LoadedCurrentlyWatching(shows: shows, counter: client.counter) {
                    await viewModel.performLazyLoad()
                }.refreshable {
                    await viewModel.performRefresh()
                    await client.checkCounter()
                }
            }
        }
        .toolbar {
            NavigationLink(destination: ProfileView()) {
                Image(systemName: "person.circle")
            }
        }
        .navigationTitle("Я смотрю")
    }
}

struct LoadedCurrentlyWatching: View {
    let shows: [WatchCardModel]
    let counter: Int
    let loadMore: () async -> Void

    @EnvironmentObject var client: ScraperClient
    var body: some View {
        List {
            if UIDevice.current.userInterfaceIdiom == .phone {
                Section {
                    NavigationLink(destination: NotificationCenterView(viewModel: .init(apiClient: client))) {
                        Label("Уведомления", systemImage: "bell")
                            .badge(counter)
                    }
                }
            }

            Section {
                ForEach(shows) { show in
                    WatchCard(data: show)
                        .task {
                            if show == self.shows.last {
                                await self.loadMore()
                            }
                        }
                }
            } header: {
                Text("Серии к просмотру")
            }
        }
    }
}

//#Preview {
//    AppPreview {
//        NavigationStack {
//            CurrentlyWatchingView(viewModel: .init(apiClient: .init(scraperClient: ServiceLocator
//                    .getScraperAPIClient())))
//        }
//    }
//}
//
//#Preview("No navigation") {
//    AppPreview {
//        CurrentlyWatchingView(viewModel: .init(apiClient: .init(scraperClient: ServiceLocator.getScraperAPIClient())))
//    }
//}
