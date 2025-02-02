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

  private(set) var state: State = .idle

  private let episodeService: EpisodeService

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
      }
      .focusable()

    case .loadedButEmpty:
      ContentUnavailableView {
        Label("Список видео пустой", systemImage: "list.bullet")
      } description: {
        Text("У этого перевода ещё нет загруженных видео, либо они находятся в обработке")
      }
      .focusable()

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

  // periphery:ignore
  @AppStorage("last_watched_translation_id") private var lastWatchedTranslationId: Int = 0

  var body: some View {
    List {
      Section {
        ForEach(self.episodeTranslationStreamingInfo.streamingQualities, id: \.videoUrl) { streamingQuality in
          Button(action: {
            var subtitlesUrl = self.episodeTranslationStreamingInfo.subtitlesUrl

            // Используем прокси-сервер только если у ссылки на файл с субтитрами нет расширения
            if let originalSubtitlesUrl = episodeTranslationStreamingInfo.subtitlesUrl,
              originalSubtitlesUrl.pathExtension.isEmpty
            {
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
      } footer: {
        if self.episodeTranslationStreamingInfo.subtitlesUrl != nil {
          Text("Этот перевод использует внешние субтитры.")
        }
      }

      Section {
        Picker("Плеер", selection: self.$selectedPlayer) {
          ForEach(ThirdPartyVideoPlayerType.allCases, id: \.self) { type in
            Text(type.name).tag(type)
          }
        }
        .pickerStyle(.navigationLink)
      } header: {
        Text("Настройки")
      }
    }
    .listStyle(.grouped)
  }
}
