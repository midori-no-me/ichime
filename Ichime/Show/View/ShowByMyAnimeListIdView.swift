import SwiftUI

@Observable
private class ShowByMyAnimeListIdViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loaded(Int)
  }

  private var _state: State = .idle
  private let showService: ShowService

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
    showService: ShowService = ApplicationDependency.container.resolve()
  ) {
    self.showService = showService
  }

  func performInitialLoad(myAnimeListId: Int) async {
    self.state = .loading

    do {
      let showId = try await showService.getShowIdByMyAnimeListId(myAnimeListId)

      self.state = .loaded(showId)
    }
    catch {
      self.state = .loadingFailed(error)
    }
  }
}

struct ShowByMyAnimeListIdView: View {
  let myAnimeListId: Int

  @State private var viewModel: ShowByMyAnimeListIdViewModel = .init()

  var body: some View {
    switch self.viewModel.state {
    case .idle:
      Color.clear.onAppear {
        Task {
          await self.viewModel.performInitialLoad(
            myAnimeListId: self.myAnimeListId
          )
        }
      }

    case .loading:
      ProgressView()
        .focusable()
        .centeredContentFix()

    case let .loadingFailed(error):
      if case GetShowByIdError.notFoundByMyAnimeListId = error {
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
                myAnimeListId: self.myAnimeListId
              )
            }
          }) {
            Text("Обновить")
          }
        }
        .centeredContentFix()
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
                myAnimeListId: self.myAnimeListId
              )
            }
          }) {
            Text("Обновить")
          }
        }
        .centeredContentFix()
      }

    case let .loaded(showId):
      ShowView(showId: showId)
    }
  }
}
