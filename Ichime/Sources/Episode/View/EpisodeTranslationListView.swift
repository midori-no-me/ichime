import IchimeAnime365
import IchimeCore
import IchimeEpisode
import IchimeShow
import SwiftData
import SwiftUI

@Observable @MainActor
private final class EpisodeTranslationListViewModel {
  // MARK: Nested Types

  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded(EpisodeInfo?, [EpisodeTranslationGroup])
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
    episodeID: Int,
    isAdultDomain: Bool,
  ) async {
    self.state = .loading

    do {
      let (episode, episodeTranslationInfos) = try await episodeService.getEpisodeTranslations(
        episodeID: episodeID
      )

      let episodeTranslationGroups = self.episodeService.filterAndGroupEpisodeTranslations(
        episodeTranslationInfos: episodeTranslationInfos,
        skipFiltering: isAdultDomain,
      )

      if episodeTranslationGroups.isEmpty {
        self.state = .loadedButEmpty
      }
      else {
        self.state = .loaded(episode, episodeTranslationGroups)
      }
    }
    catch {
      self.state = .loadingFailed(error)
    }
  }
}

struct EpisodeTranslationListView: View {
  // MARK: SwiftUI Properties

  @State private var viewModel: EpisodeTranslationListViewModel = .init()

  @AppStorage(Anime365BaseURL.UserDefaultsKey.BASE_URL, store: Anime365BaseURL.getUserDefaults()) private
    var anime365BaseURL: URL = Anime365BaseURL.DEFAULT_BASE_URL

  // MARK: Properties

  let episodeID: Int
  let showTitle: ShowName?

  // MARK: Content Properties

  var body: some View {
    Group {
      switch self.viewModel.state {
      case .idle:
        Color.clear.onAppear {
          Task {
            await self.viewModel.performInitialLoad(
              episodeID: self.episodeID,
              isAdultDomain: Anime365BaseURL.isAdultDomain(self.anime365BaseURL),
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
        } actions: {
          Button(action: {
            Task {
              await self.viewModel.performInitialLoad(
                episodeID: self.episodeID,
                isAdultDomain: Anime365BaseURL.isAdultDomain(self.anime365BaseURL),
              )
            }
          }) {
            Text("Обновить")
          }
        }

      case .loadedButEmpty:
        ContentUnavailableView {
          Label("Список переводов пустой", systemImage: "list.bullet")
        } description: {
          Text("У серии ещё нет переводов")
        } actions: {
          Button(action: {
            Task {
              await self.viewModel.performInitialLoad(
                episodeID: self.episodeID,
                isAdultDomain: Anime365BaseURL.isAdultDomain(self.anime365BaseURL),
              )
            }
          }) {
            Text("Обновить")
          }
        }

      case let .loaded(episode, episodeTranslationGroups):
        List {
          ForEach(episodeTranslationGroups) { episodeTranslationGroup in
            Section(header: Text(episodeTranslationGroup.groupType.title)) {
              ForEach(episodeTranslationGroup.episodeTranslationInfos) { episodeTranslationInfo in
                EpisodeTranslationRow(
                  episodeTranslationInfo: episodeTranslationInfo,
                  showTitle: self.showTitle,
                  episodeNumber: episode?.episodeNumber
                )
              }
            }
          }
        }
        .listStyle(.grouped)
        .safeAreaPadding(.leading, 700)
        .overlay(alignment: .topLeading) {
          if let episode {
            EpisodeDetails(episode: episode)
              .frame(width: 700 - 64)
          }
        }
      }
    }
  }
}

private struct EpisodeDetails: View {
  // MARK: Properties

  let episode: EpisodeInfo

  // MARK: Content Properties

  var body: some View {
    VStack(alignment: .leading, spacing: 32) {
      Group {
        VStack {
          Group {
            Text(self.episode.anime365Title)
              .font(.title2)

            if let officialTitle = episode.officialTitle {
              Text(officialTitle)
                .font(.title3)
                .foregroundStyle(.secondary)
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        if let duration = self.episode.duration {
          Label(duration.formatted(.units(width: .narrow)), systemImage: "clock")
        }

        if self.episode.isFiller {
          Label("Филлер", systemImage: "circle.lefthalf.filled")
        }

        if self.episode.isRecap {
          Label("Рекап", systemImage: "repeat.circle")
        }

        if let synopsis = episode.synopsis {
          Text(synopsis)
        }

        if let officiallyAiredAt = episode.officiallyAiredAt {
          Label(formatRelativeDate(officiallyAiredAt), systemImage: "calendar")
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

private struct EpisodeTranslationRow: View {
  // MARK: Properties

  let episodeTranslationInfo: EpisodeTranslationInfo
  let showTitle: ShowName?
  let episodeNumber: Int?

  // MARK: Content Properties

  var body: some View {
    NavigationLink(
      destination: EpisodeQualitySelectorListView(
        translationID: self.episodeTranslationInfo.id,
        showTitle: self.showTitle,
        episodeNumber: self.episodeNumber,
      )
    ) {
      HStack {
        Text(self.episodeTranslationInfo.translationTeam)

        Spacer()

        Text(self.formatTranslationQuality())
          .foregroundStyle(.secondary)
      }
    }
  }

  // MARK: Functions

  private func formatTranslationQuality() -> String {
    var stringComponents: [String] = []

    if self.episodeTranslationInfo.isUnderProcessing {
      stringComponents.append("В обработке")
    }

    if self.episodeTranslationInfo.sourceVideoQuality == .bd {
      stringComponents.append("BD")
    }

    stringComponents.append(self.episodeTranslationInfo.height.formatted(VideoQualityNumberFormatter()))

    return stringComponents.joined(separator: " • ")
  }
}
