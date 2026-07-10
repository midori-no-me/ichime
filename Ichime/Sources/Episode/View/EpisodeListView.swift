import IchimeCore
import IchimeEpisode
import IchimeShow
import OrderedCollections
import SwiftData
import SwiftUI

@Observable @MainActor
private final class EpisodeListViewModel {
  // MARK: Nested Types

  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded(episodes: OrderedSet<EpisodeInfo>)
  }

  // MARK: Properties

  private(set) var state: State = .idle

  private let episodeService: EpisodeService

  // MARK: Lifecycle

  init(
    episodeService: EpisodeService = AppDependencies.live.episodeService,
  ) {
    self.episodeService = episodeService
  }

  // MARK: Functions

  func performInitialLoading(showID: Int) async {
    self.updateState(.loading)

    do {
      let episodes = try await self.episodeService.getEpisodeList(
        showID: showID,
      )

      if episodes.isEmpty {
        self.updateState(.loadedButEmpty)
      }
      else {
        self.updateState(
          .loaded(
            episodes: episodes,
          )
        )
      }
    }
    catch {
      self.updateState(.loadingFailed(error))
    }
  }

  private func updateState(_ state: State) {
    withAnimation(.easeInOut(duration: 0.5)) {
      self.state = state
    }
  }
}

struct EpisodeListView: View {
  // MARK: SwiftUI Properties

  @State private var viewModel: EpisodeListViewModel = .init()

  // MARK: Properties

  let showID: Int
  let nextEpisodeReleasesAt: Date?
  let showTitle: ShowName?

  // MARK: Content Properties

  var body: some View {
    switch self.viewModel.state {
    case .idle:
      Color.clear.onAppear {
        Task {
          await self.viewModel.performInitialLoading(
            showID: self.showID,
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
            await self.viewModel.performInitialLoading(
              showID: self.showID,
            )
          }
        }) {
          Text("Обновить")
        }
      }

    case .loadedButEmpty:
      ContentUnavailableView {
        Label("Список серий пустой", systemImage: "list.bullet")
      } description: {
        Text("У этого тайтла ещё нет загруженных серий")
      } actions: {
        Button(action: {
          Task {
            await self.viewModel.performInitialLoading(
              showID: self.showID,
            )
          }
        }) {
          Text("Обновить")
        }
      }

    case let .loaded(episodeInfos):
      List {
        Section {
          ForEach(episodeInfos) { episodeInfo in
            EpisodePreviewRow(episodeInfo: episodeInfo, showTitle: self.showTitle)
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
}

private struct EpisodePreviewRow: View {
  // MARK: SwiftUI Properties

  @FocusState private var isLinkFocused: Bool

  // MARK: Properties

  let episodeInfo: EpisodeInfo
  let showTitle: ShowName?

  // MARK: Content Properties

  var body: some View {
    NavigationLink(
      destination: EpisodeTranslationListView(
        episodeID: self.episodeInfo.anime365ID,
        showTitle: self.showTitle,
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

  // MARK: Functions

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
