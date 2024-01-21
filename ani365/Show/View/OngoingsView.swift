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
        preloadedShows: [Show]? = nil
    ) {
        if let preloadedShows = preloadedShows, !preloadedShows.isEmpty {
            self.currentOffset = preloadedShows.count
            self.shows = preloadedShows
            self.state = .loaded(self.shows)
        }

        self.client = Anime365Client(
            apiClient: Anime365ApiClient(
                baseURL: "https://anime365.ru/api",
                userAgent: "ani365"
            )
        )
    }
    

    @MainActor
    func updateState(_ newState: State) {
        state = newState
    }
    
    func performInitialLoad() async {
        await updateState(.loading)

        do {
            let shows = try await client.getOngoings(
                offset: self.currentOffset,
                limit: self.SHOWS_PER_PAGE
            )

            if shows.isEmpty {
                await updateState(.loadedButEmpty)
            } else {
                self.currentOffset = self.SHOWS_PER_PAGE
                self.shows = shows
                await updateState(.loaded(self.shows))
            }
        } catch {
            await updateState(.loadingFailed(error))
        }
    }

    func performLazyLoading() async {
        if self.stopLazyLoading {
            return
        }

        do {
            let shows = try await client.getOngoings(
                offset: self.currentOffset,
                limit: self.SHOWS_PER_PAGE
            )

            if shows.count < self.SHOWS_PER_PAGE {
                self.stopLazyLoading = true
            }

            self.currentOffset = self.currentOffset + self.SHOWS_PER_PAGE
            self.shows += shows
            await updateState(.loaded(self.shows))
        } catch {
            self.stopLazyLoading = true
        }
    }

    func performPullToRefresh() async {
        do {
            let shows = try await client.getOngoings(
                offset: 0,
                limit: self.SHOWS_PER_PAGE
            )

            if shows.isEmpty {
                await updateState(.loadedButEmpty)
            } else {
                self.currentOffset = self.SHOWS_PER_PAGE
                self.shows = shows
                await updateState(.loaded(self.shows))
            }
        } catch {
            await updateState(.loadingFailed(error))
        }

        self.stopLazyLoading = false
    }
}

struct OngoingsView: View {
    @ObservedObject var viewModel: OngoingsViewModel

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

            case .loadingFailed(let error):
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

            case .loaded(let shows):
                ScrollView([.vertical]) {
                    OngoingsViewWrapper {
                        OngoingsGrid(
                            shows: shows,
                            loadMore: { await self.viewModel.performLazyLoading() }
                        )
                        .padding(.top, 18)
                        .scenePadding(.horizontal)
                        .scenePadding(.bottom)
                    }
                }
            }
        }
        .navigationTitle("Онгоинги")
        .toolbar {
            NavigationLink(destination: OnboardingView()) {
                Image(systemName: "person.circle")
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await self.viewModel.performPullToRefresh()
        }
    }
}

private struct OngoingsViewWrapper<Content>: View where Content: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack {
            Text("Сериалы, у которых продолжают выходить новые серии")
                .font(.title3)
                .scenePadding(.horizontal)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)

            Spacer()

            self.content

            Spacer()
        }
    }
}

private struct OngoingsGrid: View {
    let shows: [Show]
    let loadMore: () async -> ()

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12, alignment: .topLeading)], spacing: 18) {
            ForEach(self.shows) { show in
                ShowCard(show: show)
                    .frame(height: 300)
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
        OngoingsView(viewModel: .init())
    }
}
