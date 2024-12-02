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
  private let videoHolder: VideoPlayerHolder
  private let playerPreference: PlayerPreference = .init()

  init(
    client: Anime365Client = ApplicationDependency.container.resolve(),
    scraperClient: ScraperAPI.APIClient = ApplicationDependency.container.resolve(),
    videoHolder: VideoPlayerHolder = ApplicationDependency.container.resolve()
  ) {
    self.client = client
    self.scraperClient = scraperClient
    self.videoHolder = videoHolder
  }

  @MainActor
  func updateState(_ newState: State) {
    state = newState
  }

  private var translationId: Int = 0
  private var episodeId: Int = 0

  func performInitialLoad(episodeId: Int, translationId: Int) async {
    self.translationId = translationId
    self.episodeId = episodeId
    await updateState(.loading)

    do {
      let episodeStreamingInfo = try await client.getEpisodeStreamingInfo(
        translationId: translationId
      )

      if episodeStreamingInfo.streamQualityOptions.isEmpty {
        await updateState(.loadedButEmpty)
      }
      else {
        await updateState(.loaded(episodeStreamingInfo))
      }
    }
    catch {
      await updateState(.loadingFailed(error))
    }
  }

  func performUpdateWatch(translationId: Int) async {
    do {
      try await scraperClient.sendAPIRequest(
        ScraperAPI.Request
          .UpdateCurrentWatch(translationId: translationId)
      )
    }
    catch {
      print(error.localizedDescription)
    }
  }

  private(set) var selectedVideoUrl: URL?
  var shownCompleteAlert = false
  var shownChangePlayerAlert = false
  var dismissModal: (() -> Void)?

  var defaultPlayer: PlayerPreference.Player {
    playerPreference.selectedPlayer
  }

  func playThroughURL(video: URL, subtitle: URL?, player: PlayerPreference.Player) {
    if subtitle != nil, player.supportSubtitle == false {
      shownChangePlayerAlert = true
      return
    }

    if let url = playerPreference.getLink(type: player, video: video, subtitle: subtitle) {
      print(url)
      UIApplication.shared.open(url)
    }

    selectedVideoUrl = nil
    shownCompleteAlert = true
  }

  func playThroughInbuildPlayer(video: URL, subtitle: URL?) {
    Task {
      let collector = MetadataCollector(
        episodeId: self.episodeId,
        translationId: self.translationId
      )
      let metadata = await collector.getMetadata()

      await self.videoHolder.play(
        video: .init(
          videoURL: video,
          subtitleURL: subtitle,
          metadata: metadata,
          translationId: translationId
        ),
        onDismiss: {
          if let dismissModal = self.dismissModal {
            dismissModal()
          }
        }
      )

      self.selectedVideoUrl = nil
    }
  }

  func handleStartPlay(
    video: URL,
    subtitle: EpisodeStreamingInfo.SubtitlesUrls?,
    dismiss: @escaping () -> Void
  ) {
    handleStartPlay(video: video, subtitle: subtitle, dismiss: dismiss, player: defaultPlayer)
  }

  func handleStartPlay(
    video: URL,
    subtitle: EpisodeStreamingInfo.SubtitlesUrls?,
    dismiss: @escaping () -> Void,
    player: PlayerPreference.Player
  ) {
    shownChangePlayerAlert = false
    selectedVideoUrl = video
    dismissModal = dismiss

    if player == .iOS {
      playThroughInbuildPlayer(video: video, subtitle: subtitle?.vtt)
    }
    else {
      playThroughURL(video: video, subtitle: subtitle?.base, player: player)
    }
  }

  func checkWatch() async {
    try? await scraperClient.sendAPIRequest(
      ScraperAPI.Request
        .UpdateCurrentWatch(translationId: translationId)
    )
    shownCompleteAlert = false
    if let dismissModal = dismissModal {
      dismissModal()
    }
  }

  func hideAlert() {
    shownCompleteAlert = false
  }
}

struct EpisodeTranslationQualitySelectorView: View {
  @Environment(\.dismiss) private var dismiss

  let episodeId: Int
  let translationId: Int
  let translationTeam: String
  let disableSubs: Bool
  var videoHolder: VideoPlayerHolder = ApplicationDependency.container.resolve()

  @State private var viewModel: EpisodeTranslationQualitySelectorViewModel = .init()

  var body: some View {
    Group {
      switch self.viewModel.state {
      case .idle:
        Color.clear.onAppear {
          Task {
            await self.viewModel.performInitialLoad(
              episodeId: episodeId,
              translationId: translationId
            )
          }
        }

      case .loading:
        ProgressView()
          .focusable()

      case let .loadingFailed(error):
        ContentUnavailableView {
          Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
        } description: {
          Text(error.localizedDescription)
        }

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
                  viewModel.handleStartPlay(
                    video: url,
                    subtitle: !disableSubs ? episodeStreamingInfo.subtitles : nil,
                    dismiss: {
                      dismiss()
                    }
                  )
                }) {
                  HStack {
                    Text("\(String(streamQualityOption.height))p")
                    if viewModel.selectedVideoUrl == url {
                      Spacer()
                      ProgressView()
                    }
                  }
                }
                .alert(
                  "Выбранный плеер не поддерживает субтитры, запустить в",
                  isPresented: $viewModel.shownChangePlayerAlert,
                  actions: {
                    if let url = viewModel.selectedVideoUrl {
                      Button("Встроенный") {
                        viewModel.handleStartPlay(
                          video: url,
                          subtitle: !disableSubs ? episodeStreamingInfo.subtitles : nil,
                          dismiss: { dismiss() },
                          player: .iOS
                        )
                      }
                      Button("Infuse") {
                        viewModel.handleStartPlay(
                          video: url,
                          subtitle: !disableSubs ? episodeStreamingInfo.subtitles : nil,
                          dismiss: { dismiss() },
                          player: .Infuse
                        )
                      }
                    }
                  }
                )
                .alert("Отметить как просмотренное?", isPresented: $viewModel.shownCompleteAlert) {
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

          }
        }
        .listStyle(.grouped)

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

  }
}

#Preview {
  NavigationStack {
    EpisodeTranslationQualitySelectorView(
      episodeId: 184_037,
      translationId: 3_061_769,
      translationTeam: "Crunchyroll",
      disableSubs: false
    )
  }
}
