import SwiftData
import SwiftUI

@Observable @MainActor
private final class EpisodeTranslationListViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded(EpisodeInfo?, [EpisodeTranslationGroup])
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
    episodeId: Int
  ) async {
    self.state = .loading

    do {
      let (episode, episodeTranslationInfos) = try await episodeService.getEpisodeTranslations(
        episodeId: episodeId
      )

      let episodeTranslationGroups = self.episodeService.filterAndGroupEpisodeTranslations(
        episodeTranslationInfos: episodeTranslationInfos
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
  let episodeId: Int

  @State private var viewModel: EpisodeTranslationListViewModel = .init()

  var body: some View {
    Group {
      switch self.viewModel.state {
      case .idle:
        Color.clear.onAppear {
          Task {
            await self.viewModel.performInitialLoad(
              episodeId: self.episodeId
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
                episodeId: self.episodeId
              )
            }
          }) {
            Text("Обновить")
          }
        }
        .centeredContentFix()

      case .loadedButEmpty:
        ContentUnavailableView {
          Label("Список переводов пустой", systemImage: "list.bullet")
        } description: {
          Text("У серии ещё нет переводов")
        } actions: {
          Button(action: {
            Task {
              await self.viewModel.performInitialLoad(
                episodeId: self.episodeId
              )
            }
          }) {
            Text("Обновить")
          }
        }
        .centeredContentFix()

      case let .loaded(episode, episodeTranslationGroups):
        List {
          ForEach(episodeTranslationGroups) { episodeTranslationGroup in
            Section(header: Text(episodeTranslationGroup.groupType.title)) {
              ForEach(episodeTranslationGroup.episodeTranslationInfos) { episodeTranslationInfo in
                EpisodeTranslationRow(episodeTranslationInfo: episodeTranslationInfo)
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
  let episode: EpisodeInfo

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
  let episodeTranslationInfo: EpisodeTranslationInfo

  var body: some View {
    NavigationLink(
      destination: EpisodeQualitySelectorListView(
        translationId: self.episodeTranslationInfo.id
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
