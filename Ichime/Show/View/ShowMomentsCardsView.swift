//
//  ShowMomentsCardsView.swift
//  Ichime
//
//  Created by Nikita Nafranets on 27.03.2024.
//

import ScraperAPI
import SwiftUI

@Observable
class ShowMomentsCardsViewModel {
    enum State {
        case idle
        case loading
        case loadingFailed(Error)
        case loadedButEmpty
        case loaded([ScraperAPI.Types.Moment])
    }

    private(set) var state = State.idle

    private let api: ScraperAPI.APIClient
    private let videoHolder: VideoPlayerHolder

    init(
        scraperClient: ScraperAPI.APIClient = ApplicationDependency.container.resolve(),
        videoPlayerHolder: VideoPlayerHolder = ApplicationDependency.container.resolve()
    ) {
        api = scraperClient
        videoHolder = videoPlayerHolder
    }

    func performInitialLoad(showId: Int) async {
        state = .loading

        await performPullToRefresh(showId: showId)
    }

    func performPullToRefresh(showId: Int) async {
        do {
            let moments = try await api.sendAPIRequest(
                ScraperAPI.Request.GetMomentsByShow(showId: showId)
            )

            if moments.isEmpty {
                state = .loadedButEmpty
            } else {
                state = .loaded(moments)
            }
        } catch {
            state = .loadingFailed(error)
        }
    }

    func showMoment(id: Int, showName: String) async {
        do {
            let embed = try await api.sendAPIRequest(ScraperAPI.Request.GetMomentEmbed(momentId: id))

            guard let video = embed.video.first,
                  let videoHref = video.urls.first,
                  let videoURL = URL(string: videoHref)
            else {
                return
            }

            await videoHolder.play(video: .init(
                videoURL: videoURL,
                subtitleURL: nil,
                metadata: .init(
                    title: embed.title,
                    subtitle: showName,
                    description: nil,
                    genre: nil,
                    image: nil,
                    year: nil
                ),
                translationId: nil
            ))
        } catch {
            print(error)
        }
    }

    public func getShowMomentsFetchFunction(showId: Int) -> (_ page: Int) async throws -> [ScraperAPI.Types.Moment] {
        func fetchFunction(_ page: Int) async throws -> [ScraperAPI.Types.Moment] {
            return try await api.sendAPIRequest(
                ScraperAPI.Request.GetMomentsByShow(showId: showId, page: page)
            )
        }

        return fetchFunction
    }
}

struct ShowMomentsCardsView: View {
    #if os(tvOS)
        private static let SPACING_BETWEEN_TITLE_AND_CARDS: CGFloat = 50
    #else
        private static let SPACING_BETWEEN_TITLE_AND_CARDS: CGFloat = 20
    #endif

    let showId: Int
    let showName: String
    @State var viewModel: ShowMomentsCardsViewModel = .init()

    var body: some View {
        VStack(alignment: .leading, spacing: ShowMomentsCardsView.SPACING_BETWEEN_TITLE_AND_CARDS) {
            SectionHeader(
                title: "Моменты",
                subtitle: nil
            ) {
                MomentsView(
                    viewModel: .init(
                        fetchMoments: viewModel.getShowMomentsFetchFunction(showId: showId)
                    ),
                    title: "Моменты",
                    description: showName
                )
            }

            Group {
                switch viewModel.state {
                case .idle:
                    Color.clear.onAppear {
                        Task {
                            await self.viewModel.performInitialLoad(showId: showId)
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
                    #if !os(tvOS)
                    .textSelection(.enabled)
                    #endif

                case .loadedButEmpty:
                    ContentUnavailableView {
                        Label("Ничего не нашлось", systemImage: "list.bullet")
                    } description: {
                        Text("Возможно, это баг")
                    }

                case let .loaded(moments):
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack {
                            ForEach(moments) { moment in
                                MomentCard(
                                    title: moment.title,
                                    cover: moment.preview,
                                    websiteUrl: URL(string: "https://anime365.ru/moments/219167")!,
                                    id: moment.id
                                ) {
                                    Task {
                                        await viewModel.showMoment(id: moment.id, showName: showName)
                                    }
                                }
                            }
                        }
                    }
                    .scrollClipDisabled(true)
                }
            }
        }
    }
}

#Preview {
    ShowMomentsCardsView(showId: 8762, showName: "One piece")
}
