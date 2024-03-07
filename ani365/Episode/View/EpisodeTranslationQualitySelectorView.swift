//
//  EpisodeTranslationQualityView.swift
//  ani365
//
//  Created by p.flaks on 17.01.2024.
//

import SwiftUI

@Observable
class EpisodeTranslationQualitySelectorViewModel {
    enum State {
        case idle
        case loading
        case loadingFailed(Error)
        case loadedButEmpty
        case loaded(EpisodeStreamingInfo)
    }

    private(set) var state = State.idle

    private let client: Anime365Client

    init(
        client: Anime365Client = ApplicationDependency.container.resolve()
    ) {
        self.client = client
    }

    @MainActor
    func updateState(_ newState: State) {
        state = newState
    }

    func performInitialLoad(translationId: Int) async {
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

    let translationId: Int
    let translationTeam: String
    @ObservedObject var videoPlayerController: VideoPlayerController = .init()

    @State private var viewModel: EpisodeTranslationQualitySelectorViewModel = .init()

    var body: some View {
        Group {
            switch self.viewModel.state {
            case .idle:
                Color.clear.onAppear {
                    Task {
                        await self.viewModel.performInitialLoad(translationId: translationId)
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

            case .loadedButEmpty:
                ContentUnavailableView {
                    Label("Ничего не нашлось", systemImage: "list.bullet")
                } description: {
                    Text("Скорее всего, что-то пошло не так")
                }

            case let .loaded(episodeStreamingInfo):
                List {
                    Section {
                        ForEach(episodeStreamingInfo.streamQualityOptions) { streamQualityOption in
                            ForEach(streamQualityOption.urls, id: \.self) { url in
                                Button(action: {
                                    Task {
                                        dismiss()
                                        await self.videoPlayerController.play(video:
                                            .init(
                                                videoURL: url,
                                                subtitleURL: episodeStreamingInfo.subtitles?.vtt,
                                                title: nil,
                                                episodeTitle: nil
                                            ))
                                    }
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
        .navigationTitle(translationTeam)
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
        EpisodeTranslationQualitySelectorView(
            translationId: 3_061_769,
            translationTeam: "Crunchyroll"
        )
    }
}
