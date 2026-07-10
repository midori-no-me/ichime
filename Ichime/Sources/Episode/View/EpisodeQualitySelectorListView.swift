import Anime365Kit
import IchimeEpisode
import IchimeShow
import IchimeVideoPlayer
import SwiftData
import SwiftUI
import ThirdPartyVideoPlayer

@Observable @MainActor
private final class EpisodeQualitySelectorListViewModel {
  // MARK: Nested Types

  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded(EpisodeTranslationStreamingInfo)
  }

  // MARK: Properties

  private var _state: State = .idle
  private let episodeService: EpisodeService

  // MARK: Computed Properties

  private(set) var state: State {
    get {
      self._state
    }
    set {
      withAnimation {
        self._state = newValue
      }
    }
  }

  // MARK: Lifecycle

  init(
    episodeService: EpisodeService = AppDependencies.live.episodeService
  ) {
    self.episodeService = episodeService
  }

  // MARK: Functions

  func performInitialLoad(
    translationID: Int
  ) async {
    self.state = .loading

    do {
      let episodeTranslationStreamingInfo = try await episodeService.getTranslationStreamingData(
        translationID: translationID
      )

      if episodeTranslationStreamingInfo.streamingQualities.isEmpty {
        self.state = .loadedButEmpty
      }
      else {
        self.state = .loaded(episodeTranslationStreamingInfo)
      }
    }
    catch {
      self.state = .loadingFailed(error)
    }
  }
}

struct EpisodeQualitySelectorListView: View {
  // MARK: SwiftUI Properties

  @State private var viewModel: EpisodeQualitySelectorListViewModel = .init()

  // MARK: Properties

  let translationID: Int
  let showTitle: ShowName?
  let episodeNumber: Int?

  // MARK: Content Properties

  var body: some View {
    switch self.viewModel.state {
    case .idle:
      Color.clear.onAppear {
        Task {
          await self.viewModel.performInitialLoad(
            translationID: self.translationID
          )
        }
      }

    case .loading:
      ProgressView()
        .focusable()

    case let .loadingFailed(error):
      if case let Anime365Kit.ApiClientError.apiError(apiError) = error, case .authenticationRequired = apiError {
        AuthenticationRequiredContentUnavailableView(onSuccessfulAuth: {
          Task {
            await self.viewModel.performInitialLoad(
              translationID: self.translationID
            )
          }
        })
      }
      else {
        ContentUnavailableView {
          Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
        } description: {
          Text(error.localizedDescription)
        } actions: {
          Button(action: {
            Task {
              await self.viewModel.performInitialLoad(
                translationID: self.translationID
              )
            }
          }) {
            Text("Обновить")
          }
        }
      }

    case .loadedButEmpty:
      ContentUnavailableView {
        Label("Список видео пустой", systemImage: "list.bullet")
      } description: {
        Text("У этого перевода ещё нет загруженных видео, либо они находятся в обработке")
      } actions: {
        Button(action: {
          Task {
            await self.viewModel.performInitialLoad(
              translationID: self.translationID
            )
          }
        }) {
          Text("Обновить")
        }
      }

    case let .loaded(episodeTranslationStreamingInfo):
      EpisodeTranslationsStreamingQualities(
        translationID: self.translationID,
        episodeTranslationStreamingInfo: episodeTranslationStreamingInfo,
        showTitle: self.showTitle,
        episodeNumber: self.episodeNumber,
      )
    }
  }
}

private struct EpisodeTranslationsStreamingQualities: View {
  // MARK: SwiftUI Properties

  @AppStorage("defaultPlayer") private var selectedPlayer: ThirdPartyVideoPlayerType = .infuse
  @AppStorage("preferSubtitlesProxy") private var preferSubtitlesProxy: Bool = false

  @AppStorage("last_watched_translation_id") private var lastWatchedTranslationID: Int = 0

  @Environment(\.openURL) private var openURL

  @Environment(\.dependencies) private var dependencies

  // MARK: Properties

  let translationID: Int
  let episodeTranslationStreamingInfo: EpisodeTranslationStreamingInfo
  let showTitle: ShowName?
  let episodeNumber: Int?

  // MARK: Content Properties

  var body: some View {
    List {
      Section {
        ForEach(self.episodeTranslationStreamingInfo.streamingQualities) { streamingQuality in
          Button(action: {
            var subtitlesURL = self.episodeTranslationStreamingInfo.subtitlesURL

            if self.isForcedToUseExternalSubtitlesProxy() || self.preferSubtitlesProxy {
              subtitlesURL = self.dependencies.subtitlesProxyURLGenerator.generate(translationID: self.translationID)
            }

            var showProperties: ShowProperties? = nil

            if let showTitle {
              showProperties = ShowProperties(
                name: showTitle.getRomajiOrFullName(),
                seasonNumber: nil,
                episodeNumber: self.episodeNumber
              )
            }

            let externalPlayerUniversalLink = DeepLinkFactory.buildUniversalLinkURL(
              externalPlayerType: self.selectedPlayer,
              videoURL: streamingQuality.videoURL,
              subtitlesURL: subtitlesURL,
              show: showProperties,
            )

            if !UIApplication.shared.canOpenURL(externalPlayerUniversalLink) {
              print("Opening App Store: \(self.selectedPlayer.appStoreURL)")

              self.openURL(self.selectedPlayer.appStoreURL)

              return
            }

            self.lastWatchedTranslationID = self.translationID

            print("Opening external player: \(externalPlayerUniversalLink.absoluteString)")

            self.openURL(externalPlayerUniversalLink)
          }) {
            Text(streamingQuality.height.formatted(VideoQualityNumberFormatter()))
          }
        }
      } header: {
        Text("Качество видео")
      }

      Section {
        Picker("Плеер", selection: self.$selectedPlayer) {
          ForEach(ThirdPartyVideoPlayerType.allCases) { type in
            Text(type.name).tag(type)
          }
        }
        .pickerStyle(.navigationLink)

        if self.translationUsesExternalSubtitles() && !self.isForcedToUseExternalSubtitlesProxy() {
          Toggle(isOn: self.$preferSubtitlesProxy) {
            Text("Прокси-сервер для внешних субтитров")
          }
        }
      } header: {
        Text("Настройки")
      } footer: {
        if self.translationUsesExternalSubtitles() {
          if !self.selectedPlayer.supportsExternalSubtitlesPlayback {
            Text(
              "\(self.selectedPlayer.name) не поддерживает воспроизведение внешних субтитров, которые присутствуют в этом переводе."
            )
          }
          else if self.isForcedToUseExternalSubtitlesProxy() {
            Text("Для этого перевода внешние субтитры будут загружаться с сервера Ichime, а не с сервера Anime 365.")
          }
          else if !self.isForcedToUseExternalSubtitlesProxy() {
            Text(
              "Если внешние субтитры не отображаются в \(self.selectedPlayer.name), попробуйте включить прокси-сервер. В таком случае субтитры будут загружаться с сервера Ichime, а не с сервера Anime 365."
            )
          }
        }
      }
    }
    .listStyle(.grouped)
  }

  // MARK: Functions

  private func translationUsesExternalSubtitles() -> Bool {
    self.episodeTranslationStreamingInfo.subtitlesURL != nil
  }

  private func isForcedToUseExternalSubtitlesProxy() -> Bool {
    if !self.translationUsesExternalSubtitles() {
      return false
    }

    // Используем прокси-сервер только если у ссылки на файл с субтитрами нет расширения
    if let originalSubtitlesURL = episodeTranslationStreamingInfo.subtitlesURL,
      originalSubtitlesURL.pathExtension.isEmpty
    {
      return true
    }

    return false
  }
}
