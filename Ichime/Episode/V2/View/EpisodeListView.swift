import SwiftData
import SwiftUI

@Observable
private class EpisodeListViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded([EpisodeInfo])
  }

  private(set) var state: State = .idle

  private let episodeService: EpisodeService

  init(
    episodeService: EpisodeService = ApplicationDependency.container.resolve()
  ) {
    self.episodeService = episodeService
  }

  func performInitialLoad(showId: Int) async {
    self.state = .loading

    do {
      let episodeInfos = try await episodeService.getEpisodeList(
        showId: showId
      )

      if episodeInfos.isEmpty {
        self.state = .loadedButEmpty
      }
      else {
        self.state = .loaded(episodeInfos)
      }
    }
    catch {
      self.state = .loadingFailed(error)
    }
  }
}

struct EpisodeListView: View {
  var showId: Int
  var nextEpisodeReleasesAt: Date?

  @State private var viewModel: EpisodeListViewModel = .init()

  var body: some View {
    switch self.viewModel.state {
    case .idle:
      Color.clear.onAppear {
        Task {
          await self.viewModel.performInitialLoad(
            showId: self.showId
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
              showId: self.showId
            )
          }
        }) {
          Text("Обновить")
        }
      }
      .centeredContentFix()

    case .loadedButEmpty:
      ContentUnavailableView {
        Label("Список серий пустой", systemImage: "list.bullet")
      } description: {
        Text("У этого тайтла ещё нет загруженных серий")
      } actions: {
        Button(action: {
          Task {
            await self.viewModel.performInitialLoad(
              showId: self.showId
            )
          }
        }) {
          Text("Обновить")
        }
      }
      .centeredContentFix()

    case let .loaded(episodeInfos):
      EpisodePreviews(
        episodeInfos: episodeInfos,
        nextEpisodeReleasesAt: self.nextEpisodeReleasesAt
      )
    }
  }
}

private struct EpisodePreviews: View {
  let episodeInfos: [EpisodeInfo]
  let nextEpisodeReleasesAt: Date?

  var body: some View {
    List {
      Section {
        ForEach(self.episodeInfos, id: \.anime365Id) { episodeInfo in
          EpisodePreviewRow(episodeInfo: episodeInfo)
        }
      } header: {
        Text("Серии")
      } footer: {
        if let nextEpisodeReleasesAt {
          Text(
            "Следующая серия: \(formatRelativeDateWithWeekdayNameAndDateAndTime(nextEpisodeReleasesAt).lowercased())."
          )
        }
      }
    }
    .listStyle(.grouped)
  }
}

private struct EpisodePreviewRow: View {
  @FocusState private var isLinkFocused: Bool

  let episodeInfo: EpisodeInfo

  var body: some View {
    NavigationLink(
      destination: EpisodeTranslationListView(
        episodeId: self.episodeInfo.anime365Id
      )
    ) {
      HStack(spacing: 32) {
        Group {
          if let episodeNumber = episodeInfo.episodeNumber {
            Text(episodeNumber.formatted(EpisodeNumberFormatter()))
          }
          else {
            Text("")
          }
        }
        .foregroundStyle(.secondary)
        .frame(minWidth: 64, alignment: .leading)

        Text(self.formatTitleLine())

        Spacer()

        Group {
          if self.isLinkFocused, let myAnimeListScore = episodeInfo.myAnimeListScore {
            Text("★ \(myAnimeListScore.formatted(.number.precision(.fractionLength(2))))")
          }
          else {
            Text(formatRelativeDate(self.episodeInfo.officiallyAiredAt ?? self.episodeInfo.uploadedAt))
          }
        }
        .frame(minWidth: 300, alignment: .trailing)
        .foregroundStyle(.secondary)
      }
    }
    .focused(self.$isLinkFocused)
  }

  private func formatTitleLine() -> String {
    var titleLineComponents: [String] = [
      episodeInfo.officialTitle ?? self.episodeInfo.anime365Title
    ]

    var episodeProperties: [String] = []

    if self.episodeInfo.isFiller {
      episodeProperties.append("Филлер")
    }

    if self.episodeInfo.isRecap {
      episodeProperties.append("Рекап")
    }

    if !episodeProperties.isEmpty {
      titleLineComponents.append(episodeProperties.formatted(.list(type: .and, width: .narrow)))
    }

    return titleLineComponents.joined(separator: " — ")
  }
}
