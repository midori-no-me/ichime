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

  private(set) var state: State = .idle

  private(set) var selectedVideoUrl: URL?
  var shownCompleteAlert = false
  var shownChangePlayerAlert = false
  var dismissModal: (() -> Void)?

  private let client: Anime365Client
  private let scraperClient: ScraperAPI.APIClient
  private let videoHolder: VideoPlayerHolder
  private let playerPreference: PlayerPreference = .init()

  private var translationId: Int = 0
  private var episodeId: Int = 0

  var defaultPlayer: PlayerPreference.Player {
    self.playerPreference.selectedPlayer
  }

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
    self.state = newState
  }

  func performInitialLoad(episodeId: Int, translationId: Int) async {
    self.translationId = translationId
    self.episodeId = episodeId
    await self.updateState(.loading)

    do {
      let episodeStreamingInfo = try await client.getEpisodeStreamingInfo(
        translationId: translationId
      )

      if episodeStreamingInfo.streamQualityOptions.isEmpty {
        await self.updateState(.loadedButEmpty)
      }
      else {
        await self.updateState(.loaded(episodeStreamingInfo))
      }
    }
    catch {
      await self.updateState(.loadingFailed(error))
    }
  }

  func performUpdateWatch(translationId: Int) async {
    do {
      try await self.scraperClient.sendAPIRequest(
        ScraperAPI.Request
          .UpdateCurrentWatch(translationId: translationId)
      )
    }
    catch {
      print(error.localizedDescription)
    }
  }

  func playThroughURL(video: URL, subtitle: URL?, player: PlayerPreference.Player) {
    if subtitle != nil, player.supportSubtitle == false {
      self.shownChangePlayerAlert = true
      return
    }

    if let url = playerPreference.getLink(type: player, video: video, subtitle: subtitle) {
      print(url)
      UIApplication.shared.open(url)
    }

    self.selectedVideoUrl = nil
    self.shownCompleteAlert = true
  }

  func handleStartPlay(
    video: URL,
    subtitle: EpisodeStreamingInfo.SubtitlesUrls?,
    dismiss: @escaping () -> Void
  ) {
    self.handleStartPlay(video: video, subtitle: subtitle, dismiss: dismiss, player: self.defaultPlayer)
  }

  func handleStartPlay(
    video: URL,
    subtitle: EpisodeStreamingInfo.SubtitlesUrls?,
    dismiss: @escaping () -> Void,
    player: PlayerPreference.Player
  ) {
    self.shownChangePlayerAlert = false
    self.selectedVideoUrl = video
    self.dismissModal = dismiss

    self.playThroughURL(video: video, subtitle: subtitle?.base, player: player)
  }

  func checkWatch() async {
    try? await self.scraperClient.sendAPIRequest(
      ScraperAPI.Request
        .UpdateCurrentWatch(translationId: self.translationId)
    )
    self.shownCompleteAlert = false
    if let dismissModal = dismissModal {
      dismissModal()
    }
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
              episodeId: self.episodeId,
              translationId: self.translationId
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
        .focusable()

      case .loadedButEmpty:
        ContentUnavailableView {
          Label("Ничего не нашлось", systemImage: "list.bullet")
        } description: {
          Text("Скорее всего, что-то пошло не так")
        }
        .focusable()

      case let .loaded(episodeStreamingInfo):
        List {
          Section {
            ForEach(episodeStreamingInfo.streamQualityOptions) { streamQualityOption in
              ForEach(streamQualityOption.urls, id: \.self) { url in
                Button(action: {
                  self.viewModel.handleStartPlay(
                    video: url,
                    subtitle: !self.disableSubs ? episodeStreamingInfo.subtitles : nil,
                    dismiss: {
                      self.dismiss()
                    }
                  )
                }) {
                  HStack {
                    Text("\(String(streamQualityOption.height))p")
                    if self.viewModel.selectedVideoUrl == url {
                      Spacer()
                      ProgressView()
                    }
                  }
                }
                .alert(
                  "Выбранный плеер не поддерживает субтитры, запустить в",
                  isPresented: self.$viewModel.shownChangePlayerAlert,
                  actions: {
                    if let url = viewModel.selectedVideoUrl {
                      Button("Infuse") {
                        self.viewModel.handleStartPlay(
                          video: url,
                          subtitle: !self.disableSubs ? episodeStreamingInfo.subtitles : nil,
                          dismiss: { self.dismiss() },
                          player: .Infuse
                        )
                      }
                    }
                  }
                )
                .alert("Отметить как просмотренное?", isPresented: self.$viewModel.shownCompleteAlert) {
                  Button("Нет", role: .cancel) {
                    self.viewModel.hideAlert()
                  }

                  Button("Да") {
                    Task {
                      await self.viewModel.checkWatch()
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
