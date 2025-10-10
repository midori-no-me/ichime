import OrderedCollections
import SwiftUI

@Observable @MainActor
private final class ShowInMyListStatusButtonViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loaded(AnimeListEditableEntry)
  }

  private var _state: State = .idle
  private let animeListService: AnimeListService

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
    animeListService: AnimeListService = ApplicationDependency.container.resolve()
  ) {
    self.animeListService = animeListService
  }

  func performInitialLoad(
    showId: Int
  ) async {
    self.state = .loading

    do {
      let animeListEditableEntry = try await animeListService.getAnimeListEditableEntry(
        showId: showId
      )

      self.state = .loaded(animeListEditableEntry)
    }
    catch {
      self.state = .loadingFailed(error)
    }
  }

  func performRefresh(
    showId: Int
  ) async {
    do {
      let animeListEditableEntry = try await animeListService.getAnimeListEditableEntry(
        showId: showId
      )

      self.state = .loaded(animeListEditableEntry)
    }
    catch {
      self.state = .loadingFailed(error)
    }
  }

  func addToList(showId: Int) async {
    try? await self.animeListService.editAnimeListEntry(
      showId: showId,
      status: .planned,
      score: .none,
      episodesWatched: 0
    )
  }
}

struct ShowInMyListStatusButton: View {
  @State private var viewModel: ShowInMyListStatusButtonViewModel = .init()
  @State private var showSheet: Bool = false

  @AppStorage(CurrentUserInfo.UserDefaultsKey.ID) private var userId: Int?

  let showId: Int
  let showName: ShowName
  let episodesTotal: Int?

  var body: some View {
    Button(action: {
      if case let .loaded(animeListEditableEntry) = self.viewModel.state, animeListEditableEntry.status == .notInList {
        Task {
          await self.viewModel.addToList(showId: self.showId)
          await self.viewModel.performRefresh(showId: self.showId)
        }

        return
      }

      self.showSheet = true
    }) {
      Group {
        switch self.viewModel.state {
        case .idle:
          Label("Добавить в список", systemImage: "plus")
            .labelStyle(.iconOnly)
            .onAppear {
              Task {
                await self.viewModel.performInitialLoad(showId: self.showId)
              }
            }
        case .loading:
          Label("Добавить в список", systemImage: "plus")
            .labelStyle(.iconOnly)

        case .loadingFailed(_):
          Label("Добавить в список", systemImage: "plus")
            .labelStyle(.iconOnly)

        case let .loaded(animeListEditableEntry):
          switch animeListEditableEntry.status {
          case .watching:
            Text("Смотрю")
          case .completed:
            Text("Просмотрено")
          case .onHold:
            Text("Отложено")
          case .dropped:
            Text("Брошено")
          case .planned:
            Text("Запланировано")
          case .notInList:
            Label("Добавить в список", systemImage: "plus")
              .labelStyle(.iconOnly)
          }
        }
      }
      .font(.headline)
    }
    .disabled(self.userId == nil)
    .fullScreenCover(isPresented: self.$showSheet) {
      NavigationStack {
        EditAnimeListEntrySheet(
          showId: self.showId,
          showName: self.showName,
          episodesTotal: self.episodesTotal,
          onUpdate: {
            await self.viewModel.performRefresh(showId: self.showId)
          }
        )
      }
      .background(.thickMaterial)
    }
  }
}
