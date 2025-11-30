import OrderedCollections
import SwiftData
import SwiftUI

@Observable @MainActor
private final class AnimeListViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded([AnimeListEntriesGroup])
  }

  private(set) var state: State = .idle

  private let animeListService: AnimeListService
  private let animeListEntriesCount: AnimeListEntriesCount

  init(
    animeListService: AnimeListService = ApplicationDependency.container.resolve(),
    animeListEntriesCount: AnimeListEntriesCount = ApplicationDependency.container.resolve(),
  ) {
    self.animeListService = animeListService
    self.animeListEntriesCount = animeListEntriesCount
  }

  func performInitialLoad(
    currentUserId: Int?,
    userId: Int,
    category: AnimeListCategory
  ) async {
    self.state = .loading

    do {
      let (count, animeListEntriesGroups) = try await animeListService.getAnimeList(
        userId: userId,
        category: category
      )

      if animeListEntriesGroups.isEmpty {
        self.state = .loadedButEmpty
      }
      else {
        self.state = .loaded(animeListEntriesGroups)

        if currentUserId == userId {
          await self.animeListEntriesCount.save(
            count: count,
            category: category
          )
        }
      }
    }
    catch {
      self.state = .loadingFailed(error)
    }
  }

  func performRefresh(
    currentUserId: Int?,
    userId: Int,
    category: AnimeListCategory
  ) async {
    do {
      let (count, animeListEntriesGroups) = try await animeListService.getAnimeList(
        userId: userId,
        category: category
      )

      if animeListEntriesGroups.isEmpty {
        self.state = .loadedButEmpty
      }
      else {
        self.state = .loaded(animeListEntriesGroups)

        if currentUserId == userId {
          await self.animeListEntriesCount.save(
            count: count,
            category: category
          )
        }
      }
    }
    catch {
      self.state = .loadingFailed(error)
    }
  }
}

struct AnimeListView: View {
  let userId: Int
  let animeListCategory: AnimeListCategory

  @State private var viewModel: AnimeListViewModel = .init()
  @Environment(\.currentUserStore) private var currentUserStore

  var body: some View {
    Group {
      switch self.viewModel.state {
      case .idle:
        Color.clear.onAppear {
          Task {
            await self.viewModel.performInitialLoad(
              currentUserId: self.currentUserStore.user?.id,
              userId: self.userId,
              category: self.animeListCategory
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
                currentUserId: self.currentUserStore.user?.id,
                userId: self.userId,
                category: self.animeListCategory
              )
            }
          }) {
            Text("Обновить")
          }
        }
        .centeredContentFix()

      case .loadedButEmpty:
        ContentUnavailableView {
          Label("В этом списке ничего нет", systemImage: "list.bullet")
        } description: {
          Text("В нём нет ни одного тайтла")
        } actions: {
          Button(action: {
            Task {
              await self.viewModel.performInitialLoad(
                currentUserId: self.currentUserStore.user?.id,
                userId: self.userId,
                category: self.animeListCategory
              )
            }
          }) {
            Text("Обновить")
          }
        }
        .centeredContentFix()

      case let .loaded(animeListEntries):
        List {
          ForEach(animeListEntries) { animeListEntryGroup in
            Section {
              ForEach(animeListEntryGroup.entries) { animeListEntry in
                AnimeListEntryRowView(
                  animeListEntry: animeListEntry,
                  onUpdate: {
                    await self.viewModel.performRefresh(
                      currentUserId: self.currentUserStore.user?.id,
                      userId: self.userId,
                      category: self.animeListCategory
                    )
                  }
                )
              }
            } header: {
              Text(animeListEntryGroup.letter)
            }
            .sectionIndexLabel(animeListEntryGroup.letter)
          }
        }
        .listStyle(.grouped)
        .refreshOnAppear {
          Task {
            await self.viewModel.performRefresh(
              currentUserId: self.currentUserStore.user?.id,
              userId: self.userId,
              category: self.animeListCategory
            )
          }
        }
      }
    }
  }
}

private struct AnimeListEntryRowView: View {
  let animeListEntry: AnimeListEntry
  let onUpdate: () async -> Void

  @State private var showSheet: Bool = false

  var body: some View {
    Button(action: {
      self.showSheet = true
    }) {
      HStack {
        VStack(alignment: .leading) {
          if let russianName = animeListEntry.name.getRussian() {
            Text(russianName)

            Text(self.animeListEntry.name.getRomajiOrFullName())
              .foregroundStyle(.secondary)
          }
          else {
            Text(self.animeListEntry.name.getFullName())
          }
        }

        Spacer()

        Text(self.formatEpisodeProgressString())
          .foregroundStyle(.secondary)
      }
    }
    .fullScreenCover(isPresented: self.$showSheet) {
      NavigationStack {
        EditAnimeListEntrySheet(
          showId: self.animeListEntry.id,
          showName: self.animeListEntry.name,
          episodesTotal: self.animeListEntry.episodesTotal,
          onUpdate: self.onUpdate
        )
      }
      .background(.thickMaterial)
    }
    .contextMenu {
      NavigationLink(destination: ShowView(showId: self.animeListEntry.id)) {
        Label(self.animeListEntry.name.getRomajiOrFullName(), systemImage: "info.circle")

        if let russian = self.animeListEntry.name.getRussian() {
          Text(russian)
        }
      }
    }
  }

  private func formatEpisodeProgressString() -> String {
    var stringComponents: [String] = [
      animeListEntry.episodesWatched.formatted()
    ]

    if let totalEpisodes = self.animeListEntry.episodesTotal {
      stringComponents.append(totalEpisodes.formatted())
    }
    else {
      stringComponents.append(
        EpisodeService.formatUnknownEpisodeCountBasedOnAlreadyAiredEpisodeCount(self.animeListEntry.episodesWatched)
      )
    }

    return stringComponents.joined(separator: " / ")
  }
}
