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
    
    private var translationId: Int = 0

    func performInitialLoad(translationId: Int) async {
        self.translationId = translationId
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
    
    private(set) var selectedVideoUrl: URL?
    var shownCompleteAlert = false
    
    func handleStartPlay(video: URL, subtitle: URL?) {
        selectedVideoUrl = video
        
        let allowedCharacterSet = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")

        let videoURL = video.absoluteString.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)

        var urlString = "infuse://x-callback-url/play?url=\(videoURL ?? "")"

        if let subtitleURL = subtitle?.absoluteString.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) {
            urlString += "&sub=\(subtitleURL)"
        }

        
        if let url = URL(string: urlString) {
            print(url)
            UIApplication.shared.open(url)
        }
        
        selectedVideoUrl = nil
        shownCompleteAlert = true
        
//        Task {
//            let collector = MetadataCollector(episodeId: episodeId, translationId: translationId)
//            let metadata = await collector.getMetadata()
//
//            await videoHolder.play(video: .init(
//                videoURL: video,
//                subtitleURL: subtitle,
//                metadata: metadata,
//                translationId: translationId
//            ), onDismiss: { dismiss() })
//        }
    }
    
    func checkWatch() async {
        try? await scraperClient.sendAPIRequest(
            ScraperAPI.Request
                .UpdateCurrentWatch(translationId: translationId)
        )
        self.shownCompleteAlert = false
    }
    
    func hideAlert() {
        self.shownCompleteAlert = false
    }
}

struct EpisodeTranslationQualitySelectorView: View {
    @Environment(\.dismiss) private var dismiss

    let episodeId: Int
    let translationId: Int
    let translationTeam: String
    var videoHolder: VideoPlayerHolder = ApplicationDependency.container.resolve()

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
                    Text("Скорее всего, что-то пошло не так")
                }

            case let .loaded(episodeStreamingInfo):
                List {
                    Section {
                        ForEach(episodeStreamingInfo.streamQualityOptions) { streamQualityOption in
                            ForEach(streamQualityOption.urls, id: \.self) { url in
                                Button(action: {
                                    viewModel.handleStartPlay(video: url, subtitle: episodeStreamingInfo.subtitles?.base)
                                }) {
                                    HStack {
                                        Text("\(String(streamQualityOption.height))p")
                                        if viewModel.selectedVideoUrl == url {
                                            Spacer()
                                            ProgressView()
                                        }
                                    }
                                }.alert("Отметить как просмотренное?", isPresented: $viewModel.shownCompleteAlert) {
                                    Button("Нет", role: .cancel) {
                                        viewModel.hideAlert()
                                    }
                                    
                                    Button("Да") {
                                        Task {
                                            await viewModel.checkWatch()
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
