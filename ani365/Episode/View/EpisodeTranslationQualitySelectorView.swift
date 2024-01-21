//
//  EpisodeTranslationQualityView.swift
//  ani365
//
//  Created by p.flaks on 17.01.2024.
//

import SwiftUI

class EpisodeTranslationQualitySelectorViewModel: ObservableObject {
    enum State {
        case idle
        case loading
        case loadingFailed(Error)
        case loadedButEmpty
        case loaded(EpisodeStreamingInfo)
    }

    @Published private(set) var state = State.idle

    private let client: Anime365Client
    private let translationId: Int
    public let translationTeam: String

    init(
        translationId: Int,
        translationTeam: String
    ) {
        self.translationId = translationId
        self.translationTeam = translationTeam
        self.client = Anime365Client(
            apiClient: Anime365ApiClient(
                baseURL: "https://smotret-anime.com/api",
                userAgent: "ani365",
                accessToken: "daa123fe790458825c467e999a8bf447e8f18b48a%3A4%3A%7Bi%3A0%3Bi%3A171909%3Bi%3A1%3Bs%3A9%3A%22Pupa+Lupa%22%3Bi%3A2%3Bi%3A2592000%3Bi%3A3%3Ba%3A1%3A%7Bs%3A23%3A%22passwordChangedDateTime%22%3Bs%3A19%3A%222020-02-01+00%3A48%3A52%22%3B%7D%7D"
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
            let episodeStreamingInfo = try await client.getEpisodeStreamingInfo(
                translationId: translationId
            )

            if episodeStreamingInfo.streamQualityOptions.isEmpty {
                await updateState(.loadedButEmpty)
            } else {
                await updateState(.loaded(episodeStreamingInfo))
            }
        } catch {
            await updateState(.loadingFailed(error))
        }
    }
}

struct EpisodeTranslationQualitySelectorView: View {
    @Environment(\.dismiss) private var dismiss

    @ObservedObject var viewModel: EpisodeTranslationQualitySelectorViewModel

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

            case .loadingFailed(let error):
                ContentUnavailableView {
                    Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error.localizedDescription)
                }
                .textSelection(.enabled)

            case .loadedButEmpty:
                ContentUnavailableView {
                    Label("Ничего не нашлось", systemImage: "list.bullet")
                } description: {
                    Text("Скорее всего, что-то пошло не так")
                }

            case .loaded(let episodeStreamingInfo):
                List {
                    Section {
                        ForEach(episodeStreamingInfo.streamQualityOptions) { streamQualityOption in
                            ForEach(streamQualityOption.urls, id: \.self) { url in
                                Button(action: {
                                    print(url)
                                }) {
                                    Text("\(String(streamQualityOption.height))p")
                                }
                            }
                        }
                    } header: {
                        Text("Качество видео")
                    } footer: {
                        if episodeStreamingInfo.subtitles != nil {
                            Text("AirPlay не доступен для серий с софтсабом.")
                        }
                    }
                }
            }
        }
        .navigationTitle(self.viewModel.translationTeam)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Закрыть") {
                    self.dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        EpisodeTranslationQualitySelectorView(viewModel: .init(
            translationId: 3061769,
            translationTeam: "Crunchyroll"
        ))
    }
}
