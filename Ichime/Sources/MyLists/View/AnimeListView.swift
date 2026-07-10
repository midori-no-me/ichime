import IchimeEpisode
import IchimeMyLists
import IchimeProfile
import IchimeShow
import OrderedCollections
import SwiftData
import SwiftUI

@Observable @MainActor
private final class AnimeListViewModel {
  // MARK: Nested Types

  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded([AnimeListEntriesGroup])
  }

  // MARK: Properties

  private(set) var state: State = .idle

  private let animeListService: AnimeListService
  private let animeListEntriesCount: AnimeListEntriesCount

  // MARK: Lifecycle

  init(
    animeListService: AnimeListService = AppDependencies.live.animeListService,
    animeListEntriesCount: AnimeListEntriesCount = AppDependencies.live.animeListEntriesCount,
  ) {
    self.animeListService = animeListService
    self.animeListEntriesCount = animeListEntriesCount
  }

  // MARK: Functions

  func performInitialLoad(
    currentUserID: Int?,
    userID: Int,
    category: AnimeListCategory
  ) async {
    self.state = .loading

    do {
      let (count, animeListEntriesGroups) = try await animeListService.getAnimeList(
        userID: userID,
        category: category
      )

      if animeListEntriesGroups.isEmpty {
        self.state = .loadedButEmpty
      }
      else {
        self.state = .loaded(animeListEntriesGroups)

        if currentUserID == userID {
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
    currentUserID: Int?,
    userID: Int,
    category: AnimeListCategory
  ) async {
    do {
      let (count, animeListEntriesGroups) = try await animeListService.getAnimeList(
        userID: userID,
        category: category
      )

      if animeListEntriesGroups.isEmpty {
        self.state = .loadedButEmpty
      }
      else {
        self.state = .loaded(animeListEntriesGroups)

        if currentUserID == userID {
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
  // MARK: SwiftUI Properties

  @State private var viewModel: AnimeListViewModel = .init()
  @Environment(\.currentUserStore) private var currentUserStore

  // MARK: Properties

  let userID: Int
  let animeListCategory: AnimeListCategory

  // MARK: Content Properties

  var body: some View {
    Group {
      switch self.viewModel.state {
      case .idle:
        Color.clear.onAppear {
          Task {
            await self.viewModel.performInitialLoad(
              currentUserID: self.currentUserStore.user?.id,
              userID: self.userID,
              category: self.animeListCategory
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
                currentUserID: self.currentUserStore.user?.id,
                userID: self.userID,
                category: self.animeListCategory
              )
            }
          }) {
            Text("Обновить")
          }
        }

      case .loadedButEmpty:
        ContentUnavailableView {
          Label("В этом списке ничего нет", systemImage: "list.bullet")
        } description: {
          Text("В нём нет ни одного тайтла")
        } actions: {
          Button(action: {
            Task {
              await self.viewModel.performInitialLoad(
                currentUserID: self.currentUserStore.user?.id,
                userID: self.userID,
                category: self.animeListCategory
              )
            }
          }) {
            Text("Обновить")
          }
        }

      case let .loaded(animeListEntries):
        List {
          ForEach(animeListEntries) { animeListEntryGroup in
            Section {
              ForEach(animeListEntryGroup.entries) { animeListEntry in
                AnimeListEntryRowView(
                  animeListEntry: animeListEntry,
                  onUpdate: {
                    await self.viewModel.performRefresh(
                      currentUserID: self.currentUserStore.user?.id,
                      userID: self.userID,
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
              currentUserID: self.currentUserStore.user?.id,
              userID: self.userID,
              category: self.animeListCategory
            )
          }
        }
      }
    }
  }
}

private struct AnimeListEntryRowView: View {
  // MARK: SwiftUI Properties

  @State private var showSheet: Bool = false

  // MARK: Properties

  let animeListEntry: AnimeListEntry
  let onUpdate: () async -> Void

  // MARK: Content Properties

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
          showID: self.animeListEntry.id,
          showName: self.animeListEntry.name,
          episodesTotal: self.animeListEntry.episodesTotal,
          onUpdate: self.onUpdate
        )
      }
      .background(.thickMaterial)
    }
    .contextMenu {
      NavigationLink(destination: ShowView(showID: self.animeListEntry.id)) {
        Label(self.animeListEntry.name.getRomajiOrFullName(), systemImage: "info.circle")

        if let russian = self.animeListEntry.name.getRussian() {
          Text(russian)
        }
      }
    }
  }

  // MARK: Functions

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
