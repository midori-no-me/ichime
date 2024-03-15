import SwiftUI

class OngoingsViewModel: ObservableObject {
    enum State {
        case idle
        case loading
        case loadingFailed(Error)
        case loadedButEmpty
        case loaded([Show])
    }

    @Published private(set) var state = State.idle

    private let client: Anime365Client

    private var currentOffset: Int = 0
    private var shows: [Show] = []
    private var stopLazyLoading: Bool = false

    private let SHOWS_PER_PAGE = 20

    init(
        preloadedShows: [Show]? = nil,
        client: Anime365Client = ApplicationDependency.container.resolve()
    ) {
        if let preloadedShows = preloadedShows, !preloadedShows.isEmpty {
            currentOffset = preloadedShows.count
            shows = preloadedShows
            state = .loaded(shows)
        }

        self.client = client
    }

    @MainActor
    func updateState(_ newState: State) {
        state = newState
    }

    func performInitialLoad() async {
        await updateState(.loading)

        do {
            let shows = try await client.getOngoings(
                offset: currentOffset,
                limit: SHOWS_PER_PAGE
            )

            if shows.isEmpty {
                await updateState(.loadedButEmpty)
            } else {
                currentOffset = SHOWS_PER_PAGE
                self.shows = shows
                await updateState(.loaded(self.shows))
            }
        } catch {
            await updateState(.loadingFailed(error))
        }
    }

    func performLazyLoading() async {
        if stopLazyLoading {
            return
        }

        do {
            let shows = try await client.getOngoings(
                offset: currentOffset,
                limit: SHOWS_PER_PAGE
            )

            if shows.count < SHOWS_PER_PAGE {
                stopLazyLoading = true
            }

            currentOffset = currentOffset + SHOWS_PER_PAGE
            self.shows += shows
            await updateState(.loaded(self.shows))
        } catch {
            stopLazyLoading = true
        }
    }

    func performPullToRefresh() async {
        do {
            let shows = try await client.getOngoings(
                offset: 0,
                limit: SHOWS_PER_PAGE
            )

            if shows.isEmpty {
                await updateState(.loadedButEmpty)
            } else {
                currentOffset = SHOWS_PER_PAGE
                self.shows = shows
                await updateState(.loaded(self.shows))
            }
        } catch {
            await updateState(.loadingFailed(error))
        }

        stopLazyLoading = false
    }
}

struct OngoingsView: View {
    @StateObject private var viewModel: OngoingsViewModel = .init()

    var body: some View {
        Group {
            switch self.viewModel.state {
            case .idle:
                OngoingsViewWrapper {
                    Color.clear.onAppear {
                        Task {
                            await self.viewModel.performInitialLoad()
                        }
                    }
                }

            case .loading:
                OngoingsViewWrapper {
                    ProgressView()
                }

            case let .loadingFailed(error):
                OngoingsViewWrapper {
                    ContentUnavailableView {
                        Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error.localizedDescription)
                    }
                    .textSelection(.enabled)
                }

            case .loadedButEmpty:
                OngoingsViewWrapper {
                    ContentUnavailableView {
                        Label("Ничего не нашлось", systemImage: "list.bullet")
                    } description: {
                        Text("Возможно, это баг")
                    }
                }

            case let .loaded(shows):
                ScrollView([.vertical]) {
                    OngoingsViewWrapper {
                        OngoingsGrid(
                            shows: shows,
                            loadMore: { await self.viewModel.performLazyLoading() }
                        )
                        #if os(macOS)
                        .padding()
                        #else
                        .padding(.top, 18)
                        .scenePadding(.horizontal)
                        .scenePadding(.bottom)
                        #endif
                    }
                }
            }
        }
        .navigationTitle("Онгоинги")
        #if os(iOS)
            .toolbar {
                ProfileButton()
            }
            .navigationBarTitleDisplayMode(.large)
        #endif
            .refreshable {
                await self.viewModel.performPullToRefresh()
            }
    }
}

private struct OngoingsViewWrapper<Content>: View where Content: View {
    @ViewBuilder let content: Content

    let title = String(localized: "Сериалы, у которых продолжают выходить новые серии")
    var body: some View {
        VStack {
            #if os(iOS)
                Text(title)
                    .font(.title3)
                    .scenePadding(.horizontal)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            #endif

            Spacer()

            self.content

            Spacer()
        }
        #if os(macOS)
        .navigationSubtitle(title)
        #endif
    }
}

private struct OngoingsGrid: View {
    let shows: [Show]
    let loadMore: () async -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12, alignment: .bottom)], spacing: 18) {
            ForEach(self.shows) { show in
                ShowCard(show: show)
                    .task {
                        if show == self.shows.last {
                            await self.loadMore()
                        }
                    }
            }
        }
    }
}

#Preview {
    NavigationStack {
        OngoingsView()
    }
}
