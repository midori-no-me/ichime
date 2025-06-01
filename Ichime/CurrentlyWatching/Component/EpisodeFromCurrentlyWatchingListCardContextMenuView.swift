import SwiftData
import SwiftUI

@Observable
private class EpisodeFromCurrentlyWatchingListCardContextMenuViewModel {
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
    episodeId: Int,
    hiddenTranslationsPreference: HiddenTranslationsPreference
  ) async {
    self.state = .loading

    do {
      let (episode, episodeTranslationInfos) = try await episodeService.getEpisodeTranslations(
        episodeId: episodeId
      )

      let episodeTranslationGroups = self.episodeService.filterAndGroupEpisodeTranslations(
        episodeTranslationInfos: episodeTranslationInfos,
        hiddenTranslationsPreference: hiddenTranslationsPreference
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

struct EpisodeFromCurrentlyWatchingListCardContextMenuView: View {
  let episodeId: Int
  let showId: Int
  let showName: ShowName

  @State private var viewModel: EpisodeFromCurrentlyWatchingListCardContextMenuViewModel = .init()

  @StateObject private var hiddenTranslationsPreference: HiddenTranslationsPreferenceState = .init()

  var body: some View {
    NavigationLink(destination: ShowView(showId: self.showId)) {
      Label(self.showName.getRomajiOrFullName(), systemImage: "info.circle")

      if let russian = self.showName.getRussian() {
        Text(russian)
      }
    }

    switch self.viewModel.state {
    case .idle:
      Color.clear.onAppear {
        Task {
          await self.viewModel.performInitialLoad(
            episodeId: self.episodeId,
            hiddenTranslationsPreference: self.hiddenTranslationsPreference.getPreference()
          )
        }
      }

    case .loading:
      Section("Переводы") {
        Text("Загрузка...")
      }

    case let .loadingFailed(error):
      Section("Переводы") {
        Text("Ошибка при загрузке переводов")
        Text(error.localizedDescription)
      }

    case .loadedButEmpty:
      Section("Переводы") {
        Text("У серии ещё нет переводов")
      }

    case let .loaded(_, episodeTranslationGroups):
      ForEach(episodeTranslationGroups) { episodeTranslationGroup in
        Section(header: Text(episodeTranslationGroup.groupType.title)) {
          ForEach(episodeTranslationGroup.episodeTranslationInfos) { episodeTranslationInfo in
            EpisodeTranslationContextRow(episodeTranslationInfo: episodeTranslationInfo)
          }
        }
      }
    }
  }
}

private struct EpisodeTranslationContextRow: View {
  let episodeTranslationInfo: EpisodeTranslationInfo

  var body: some View {
    NavigationLink(
      destination: EpisodeQualitySelectorListView(
        translationId: self.episodeTranslationInfo.id
      )
    ) {
      Text(self.episodeTranslationInfo.translationTeam)

      Text(self.formatTranslationQuality())
    }
  }

  private func formatTranslationQuality() -> String {
    var stringComponents: [String] = []

    stringComponents.append(self.episodeTranslationInfo.height.formatted(VideoQualityNumberFormatter()))

    if self.episodeTranslationInfo.sourceVideoQuality == .bd {
      stringComponents.append("BD")
    }

    if self.episodeTranslationInfo.isUnderProcessing {
      stringComponents.append("В обработке")
    }

    return stringComponents.joined(separator: " • ")
  }
}
