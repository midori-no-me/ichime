import IchimeShow
import SwiftUI

@Observable @MainActor
private final class ShowByMyAnimeListIDViewModel {
  // MARK: Nested Types

  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loaded(Int)
  }

  // MARK: Properties

  private var _state: State = .idle
  private let showService: ShowService

  // MARK: Computed Properties

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

  // MARK: Lifecycle

  init(
    showService: ShowService = AppDependencies.live.showService
  ) {
    self.showService = showService
  }

  // MARK: Functions

  func performInitialLoad(myAnimeListID: Int) async {
    self.state = .loading

    do {
      let showID = try await showService.getShowIDByMyAnimeListID(myAnimeListID)

      self.state = .loaded(showID)
    }
    catch {
      self.state = .loadingFailed(error)
    }
  }
}

struct ShowByMyAnimeListIDView: View {
  // MARK: SwiftUI Properties

  @State private var viewModel: ShowByMyAnimeListIDViewModel = .init()

  // MARK: Properties

  let myAnimeListID: Int
  let onOpened: (() -> Void)?

  // MARK: Content Properties

  var body: some View {
    switch self.viewModel.state {
    case .idle:
      Color.clear.onAppear {
        Task {
          await self.viewModel.performInitialLoad(
            myAnimeListID: self.myAnimeListID
          )
        }
      }

    case .loading:
      ProgressView()
        .focusable()

    case let .loadingFailed(error):
      if case GetShowByIDError.notFoundByMyAnimeListID = error {
        ContentUnavailableView {
          Label("Ничего не нашлось", systemImage: "exclamationmark.triangle")
        } description: {
          Text(
            "Возможно, этого тайтла не существует.\nЛибо он ещё не появился в базе данных Anime 365 — это может занять до нескольких суток."
          )
        } actions: {
          Button(action: {
            Task {
              await self.viewModel.performInitialLoad(
                myAnimeListID: self.myAnimeListID
              )
            }
          }) {
            Text("Обновить")
          }
        }
      }
      else {
        ContentUnavailableView {
          Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
        } description: {
          Text(error.localizedDescription)
        } actions: {
          Button(action: {
            Task {
              await self.viewModel.performInitialLoad(
                myAnimeListID: self.myAnimeListID
              )
            }
          }) {
            Text("Обновить")
          }
        }
      }

    case let .loaded(showID):
      ShowView(showID: showID, onOpened: self.onOpened)
    }
  }
}
