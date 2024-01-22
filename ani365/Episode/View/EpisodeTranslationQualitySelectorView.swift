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
        self.client = ServiceLocator.getAnime365Client()
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
    @ObservedObject var videoPlayerController: VideoPlayerController

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
        ), videoPlayerController: .init())
    }
}
