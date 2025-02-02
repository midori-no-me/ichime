import SwiftData
import SwiftUI

@Observable
private class EpisodeTranslationListViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded([EpisodeTranslationGroup])
  }

  private(set) var state: State = .idle

  private let episodeService: EpisodeService

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
      let episodeTranslationInfos = try await episodeService.getEpisodeTranslations(
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
        self.state = .loaded(episodeTranslationGroups)
      }
    }
    catch {
      self.state = .loadingFailed(error)
    }
  }
}

struct EpisodeTranslationListView: View {
  var episodeId: Int

  @State private var viewModel: EpisodeTranslationListViewModel = .init()

  @StateObject private var hiddenTranslationsPreference: HiddenTranslationsPreferenceState = .init()

  var body: some View {
    Group {
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
          Label("Список переводов пустой", systemImage: "list.bullet")
        } description: {
          Text("У серии ещё нет переводов")
        }
        .focusable()

      case let .loaded(episodeTranslationGroups):
        EpisodeTranslations(
          episodeTranslationGroups: episodeTranslationGroups
        )
      }
    }
    .onChange(of: self.hiddenTranslationsPreference.getPreference()) {
      // Подписываемся на изменения настройки, чтобы перерисовать список переводов, если вдруг настройка изменится
      // Наверняка это можно как-то получше сделать
      Task {
        await self.viewModel.performInitialLoad(
          episodeId: self.episodeId,
          hiddenTranslationsPreference: self.hiddenTranslationsPreference.getPreference()
        )
      }
    }
  }
}

private struct EpisodeTranslations: View {
  let episodeTranslationGroups: [EpisodeTranslationGroup]

  var body: some View {
    List {
      ForEach(self.episodeTranslationGroups, id: \.groupType) { episodeTranslationGroup in
        Section(header: Text(episodeTranslationGroup.groupType.title)) {
          ForEach(episodeTranslationGroup.episodeTranslationInfos) { episodeTranslationInfo in
            EpisodeTranslationRow(episodeTranslationInfo: episodeTranslationInfo)
          }
        }
      }
    }
    .listStyle(.grouped)
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
