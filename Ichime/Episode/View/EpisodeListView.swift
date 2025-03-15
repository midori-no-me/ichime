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

  private var _state: State = .idle
  private var episodes: [EpisodeInfo] = []
  private var page: Int = 1
  private var stopLazyLoading: Bool = false

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

  func performInitialLoading(
    showId: Int,
    myAnimeListId: Int,
    totalEpisodes: Int?
  ) async {
    self.state = .loading

    do {
      let (episodes, hasMore) = try await self.episodeService.getEpisodeList(
        showId: showId,
        myAnimeListId: myAnimeListId,
        page: self.page,
        totalEpisodes: totalEpisodes
      )

      if episodes.isEmpty {
        self.state = .loadedButEmpty
      }
      else {
        self.stopLazyLoading = !hasMore
        self.page += 1
        self.episodes += episodes
        self.state = .loaded(self.episodes)
      }
    }
    catch {
      self.state = .loadingFailed(error)
    }
  }

  func performLazyLoading(
    showId: Int,
    myAnimeListId: Int,
    totalEpisodes: Int?
  ) async {
    if self.stopLazyLoading {
      return
    }

    do {
      let (episodes, hasMore) = try await self.episodeService.getEpisodeList(
        showId: showId,
        myAnimeListId: myAnimeListId,
        page: self.page,
        totalEpisodes: totalEpisodes
      )

      self.stopLazyLoading = !hasMore
      self.page += 1
      self.episodes += episodes
      self.state = .loaded(self.episodes)
    }
    catch {
      self.stopLazyLoading = true
    }
  }
}

struct EpisodeListView: View {
  let showId: Int
  let myAnimeListId: Int
  let totalEpisodes: Int?
  let nextEpisodeReleasesAt: Date?

  @State private var viewModel: EpisodeListViewModel = .init()

  var body: some View {
    switch self.viewModel.state {
    case .idle:
      Color.clear.onAppear {
        Task {
          await self.viewModel.performInitialLoading(
            showId: self.showId,
            myAnimeListId: self.myAnimeListId,
            totalEpisodes: self.totalEpisodes
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
            await self.viewModel.performInitialLoading(
              showId: self.showId,
              myAnimeListId: self.myAnimeListId,
              totalEpisodes: self.totalEpisodes
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
            await self.viewModel.performInitialLoading(
              showId: self.showId,
              myAnimeListId: self.myAnimeListId,
              totalEpisodes: self.totalEpisodes
            )
          }
        }) {
          Text("Обновить")
        }
      }
      .centeredContentFix()

    case let .loaded(episodeInfos):
      List {
        Section {
          ForEach(episodeInfos, id: \.anime365Id) { episodeInfo in
            EpisodePreviewRow(episodeInfo: episodeInfo)
              .task {
                if episodeInfo.anime365Id == episodeInfos.last?.anime365Id {
                  await self.viewModel.performLazyLoading(
                    showId: self.showId,
                    myAnimeListId: self.myAnimeListId,
                    totalEpisodes: self.totalEpisodes
                  )
                }
              }
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
