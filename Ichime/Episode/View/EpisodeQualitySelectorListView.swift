import SwiftData
import SwiftUI
import ThirdPartyVideoPlayer

@Observable
private class EpisodeQualitySelectorListViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded(EpisodeTranslationStreamingInfo)
  }

  private var _state: State = .idle
  private let episodeService: EpisodeService

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

  init(
    episodeService: EpisodeService = ApplicationDependency.container.resolve()
  ) {
    self.episodeService = episodeService
  }

  func performInitialLoad(
    translationId: Int
  ) async {
    self.state = .loading

    do {
      let episodeTranslationStreamingInfo = try await episodeService.getTranslationStreamingData(
        translationId: translationId
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
  let translationId: Int

  @State private var viewModel: EpisodeQualitySelectorListViewModel = .init()

  var body: some View {
    switch self.viewModel.state {
    case .idle:
      Color.clear.onAppear {
        Task {
          await self.viewModel.performInitialLoad(
            translationId: self.translationId
          )
        }
      }

    case .loading:
      ProgressView()
        .focusable()
        .centeredContentFix()

    case let .loadingFailed(error):
      ContentUnavailableView {
        Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
      } description: {
        Text(error.localizedDescription)
      } actions: {
        Button(action: {
          Task {
            await self.viewModel.performInitialLoad(
              translationId: self.translationId
            )
          }
        }) {
          Text("Обновить")
        }
      }
      .centeredContentFix()

    case .loadedButEmpty:
      ContentUnavailableView {
        Label("Список видео пустой", systemImage: "list.bullet")
      } description: {
        Text("У этого перевода ещё нет загруженных видео, либо они находятся в обработке")
      } actions: {
        Button(action: {
          Task {
            await self.viewModel.performInitialLoad(
              translationId: self.translationId
            )
          }
        }) {
          Text("Обновить")
        }
      }
      .centeredContentFix()

    case let .loaded(episodeTranslationStreamingInfo):
      EpisodeTranslationsStreamingQualities(
        translationId: self.translationId,
        episodeTranslationStreamingInfo: episodeTranslationStreamingInfo
      )
    }
  }
}

private struct EpisodeTranslationsStreamingQualities: View {
  let translationId: Int
  let episodeTranslationStreamingInfo: EpisodeTranslationStreamingInfo

  private let subtitlesProxyUrlGenerator: SubtitlesProxyUrlGenerator = ApplicationDependency.container.resolve()

  @AppStorage("defaultPlayer") private var selectedPlayer: ThirdPartyVideoPlayerType = .infuse
  @AppStorage("preferSubtitlesProxy") private var preferSubtitlesProxy: Bool = false

  // periphery:ignore
  @AppStorage("last_watched_translation_id") private var lastWatchedTranslationId: Int = 0

  var body: some View {
    List {
      Section {
        ForEach(self.episodeTranslationStreamingInfo.streamingQualities) { streamingQuality in
          Button(action: {
            var subtitlesUrl = self.episodeTranslationStreamingInfo.subtitlesUrl

            if self.isForcedToUseExternalSubtitlesProxy() || self.preferSubtitlesProxy {
              subtitlesUrl = self.subtitlesProxyUrlGenerator.generate(translationId: self.translationId)
            }

            let externalPlayerUniversalLink = DeepLinkFactory.buildUniversalLinkUrl(
              externalPlayerType: self.selectedPlayer,
              videoUrl: streamingQuality.videoUrl,
              subtitlesUrl: subtitlesUrl
            )

            if !UIApplication.shared.canOpenURL(externalPlayerUniversalLink) {
              print("Opening App Store: \(self.selectedPlayer.appStoreUrl)")

              UIApplication.shared.open(self.selectedPlayer.appStoreUrl)

              return
            }

            self.lastWatchedTranslationId = self.translationId

            print("Opening external player: \(externalPlayerUniversalLink.absoluteString)")

            UIApplication.shared.open(externalPlayerUniversalLink)
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

  private func translationUsesExternalSubtitles() -> Bool {
    self.episodeTranslationStreamingInfo.subtitlesUrl != nil
  }

  private func isForcedToUseExternalSubtitlesProxy() -> Bool {
    if !self.translationUsesExternalSubtitles() {
      return false
    }

    // Используем прокси-сервер только если у ссылки на файл с субтитрами нет расширения
    if let originalSubtitlesUrl = episodeTranslationStreamingInfo.subtitlesUrl,
      originalSubtitlesUrl.pathExtension.isEmpty
    {
      return true
    }

    return false
  }
}
