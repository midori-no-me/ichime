import SwiftUI

class FilteredShowsViewModel: ObservableObject {
    enum State {
        case idle
        case loading
        case loadingFailed(Error)
        case loadedButEmpty
        case loaded([Show])
    }

    @Published private(set) var state = State.idle

    private var currentOffset: Int = 0
    private var shows: [Show] = []
    private var stopLazyLoading: Bool = false
    private let fetchShows: (_ offset: Int, _ limit: Int) async throws -> [Show]

    private let SHOWS_PER_PAGE = 20

    init(
        preloadedShows: [Show]? = nil,
        fetchShows: @escaping (_ offset: Int, _ limit: Int) async throws -> [Show]
    ) {
        if let preloadedShows = preloadedShows, !preloadedShows.isEmpty {
            currentOffset = preloadedShows.count
            shows = preloadedShows
            state = .loaded(shows)
        }

        self.fetchShows = fetchShows
    }

    @MainActor
    func updateState(_ newState: State) {
        state = newState
    }

    func performInitialLoad() async {
        await updateState(.loading)

        do {
            let shows = try await fetchShows(
                currentOffset,
                SHOWS_PER_PAGE
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
            let shows = try await fetchShows(
                currentOffset,
                SHOWS_PER_PAGE
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
            let shows = try await fetchShows(
                0,
                SHOWS_PER_PAGE
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

struct FilteredShowsView: View {
    @StateObject public var viewModel: FilteredShowsViewModel

    public let title: String
    public let description: String?

    var body: some View {
        Group {
            switch self.viewModel.state {
            case .idle:
                Color.clear.onAppear {
                    Task {
                        await self.viewModel.performInitialLoad()
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
                    Label("Ничего не нашлось", systemImage: "list.bullet")
                } description: {
                    Text("Возможно, это баг")
                }

            case let .loaded(shows):
                ScrollView([.vertical]) {
                    Group {
                        #if os(tvOS)
                            Text(title)
                                .font(.title2)
                        #endif

                        if let description {
                            Text(description)
                            #if os(tvOS)
                                .font(.title3)
                            #else
                                .font(.title3)
                            #endif
                                .foregroundStyle(.secondary)
                                .horizontalScreenEdgePadding()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    FilteredShowsGrid(
                        shows: shows,
                        loadMore: { await self.viewModel.performLazyLoading() }
                    )
                    #if os(macOS)
                    .padding()
                    #else
                    .padding(.top, 8)
                    .horizontalScreenEdgePadding()
                    .scenePadding(.bottom)
                    #endif
                }
                #if os(tvOS)
                .scrollClipDisabled(true)
                #endif
            }
        }
        .refreshable {
            await self.viewModel.performPullToRefresh()
        }
        #if !os(tvOS)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
        #endif
        #if os(tvOS)
        .toolbar(.hidden, for: .tabBar)
        #endif
    }
}

private struct FilteredShowsGrid: View {
    let shows: [Show]
    let loadMore: () async -> Void

    var body: some View {
        LazyVGrid(columns: [
            GridItem(
                .adaptive(minimum: RawShowCard.RECOMMENDED_MINIMUM_WIDTH),
                spacing: RawShowCard.RECOMMENDED_SPACING,
                alignment: .topLeading
            ),
        ], spacing: RawShowCard.RECOMMENDED_SPACING) {
            ForEach(self.shows) { show in
                ShowCard(show: show, displaySeason: true)
                    .task {
                        if show == self.shows.last {
                            await self.loadMore()
                        }
                    }
            }
        }
    }
}

// #Preview {
//    NavigationStack {
//        FilteredShowsView()
//    }
// }
