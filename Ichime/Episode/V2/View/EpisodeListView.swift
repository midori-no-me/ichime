import ScraperAPI
import SwiftData
import SwiftUI

@Observable
private class EpisodeListViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
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

      self.state = .loaded(episodeInfos)
    }
    catch {
      self.state = .loadingFailed(error)
    }
  }
}

struct EpisodeListView: View {
  var showId: Int

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
      }
      .focusable()

    case let .loaded(episodeInfos):
      EpisodePreviews(episodeInfos: episodeInfos)
    }
  }
}

private struct EpisodePreviews: View {
  let episodeInfos: [EpisodeInfo]

  var body: some View {
    List {
      ForEach(self.episodeInfos, id: \.anime365Id) { episodeInfo in
        EpisodePreviewRow(episodeInfo: episodeInfo)
      }
    }
    .listStyle(.grouped)
  }
}

private struct EpisodePreviewRow: View {
  let episodeInfo: EpisodeInfo

  var body: some View {
    NavigationLink(
      destination: EpisodeTranslationsView(
        episodeId: self.episodeInfo.anime365Id,
        episodeTitle: self.formatTitleLine()
      )
    ) {
      HStack(spacing: 32) {
        Group {
          if let episodeNumber = episodeInfo.episodeNumber {
            Text(episodeNumber.formatted(.number))
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
          if let myAnimeListScore = episodeInfo.myAnimeListScore {
            Text("★ \(myAnimeListScore.formatted(.number.precision(.fractionLength(2))))")
          }
          else {
            Text("")
          }
        }
        .foregroundStyle(.secondary)
        .frame(minWidth: 120, alignment: .leading)

        Text(formatRelativeDate(self.episodeInfo.officiallyAiredAt ?? self.episodeInfo.uploadedAt))
          .foregroundStyle(.secondary)
          .frame(minWidth: 300, alignment: .trailing)
      }
    }
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
