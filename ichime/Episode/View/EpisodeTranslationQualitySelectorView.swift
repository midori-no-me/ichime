//
//  EpisodeTranslationQualityView.swift
//  ichime
//
//  Created by p.flaks on 17.01.2024.
//

import ScraperAPI
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
    private let scraperClient: ScraperAPI.APIClient

    init(
        client: Anime365Client = ApplicationDependency.container.resolve(),
        scraperClient: ScraperAPI.APIClient = ApplicationDependency.container.resolve()
    ) {
        self.client = client
        self.scraperClient = scraperClient
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

    func performUpdateWatch(translationId: Int) async {
        do {
            try await scraperClient.sendAPIRequest(
                ScraperAPI.Request
                    .UpdateCurrentWatch(translationId: translationId)
            )
        } catch {
            print(error.localizedDescription)
        }
    }
}

struct EpisodeTranslationQualitySelectorView: View {
    @Environment(\.dismiss) private var dismiss

    let episodeId: Int
    let translationId: Int
    let translationTeam: String
    @ObservedObject var videoPlayerController: VideoPlayerController = .init()

    @State private var viewModel: EpisodeTranslationQualitySelectorViewModel = .init()

    @State private var selectedUrl: URL?

    var body: some View {
        Group {
            switch self.viewModel.state {
            case .idle:
                Color.clear.onAppear {
                    videoPlayerController.addDelegate(WatchChecker(translationId: translationId))
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
                #if !os(tvOS)
                .textSelection(.enabled)
                #endif
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
                                    handleStartPlay(video: url, subtitle: episodeStreamingInfo.subtitles?.vtt)
                                }) {
                                    HStack {
                                        Text("\(String(streamQualityOption.height))p")
                                        if selectedUrl == url {
                                            Spacer()
                                            ProgressView()
                                        }
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("Качество видео")
                    } footer: {
                        #if !os(tvOS)
                            if episodeStreamingInfo.subtitles != nil {
                                Text("AirPlay не доступен для серий с софтсабом.")
                            }
                        #endif
                    }
                }
                #if os(tvOS)
                .listStyle(.grouped)
                #endif
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Закрыть") {
                    self.dismiss()
                }
            }
        }
        .navigationTitle(translationTeam)
        #if !os(tvOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    func handleStartPlay(video: URL, subtitle: URL?) {
        selectedUrl = video
        Task {
            let collector = MetadataCollector(episodeId: episodeId, translationId: translationId)
            let metadata = await collector.getMetadata()
            await self.videoPlayerController.createPlayer(
                video: .init(
                    videoURL: video,
                    subtitleURL: subtitle,
                    metadata: metadata
                )
            )
            closeModal()
        }
    }

    @MainActor
    func closeModal() {
        dismiss()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            videoPlayerController.showPlayer()
        }
    }
}

#Preview {
    NavigationStack {
        EpisodeTranslationQualitySelectorView(
            episodeId: 184_037,
            translationId: 3_061_769,
            translationTeam: "Crunchyroll"
        )
    }
}
