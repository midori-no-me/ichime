import SwiftUI

@Observable
private class ShowByMyAnimeListIdViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loaded(Int)
  }

  private(set) var state: State = .idle

  private let showService: ShowService

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
  var myAnimeListId: Int

  @State private var viewModel: ShowByMyAnimeListIdViewModel = .init()

  var body: some View {
    Group {
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
        ContentUnavailableView {
          Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
        } description: {
          Text(error.localizedDescription)
        }
        .focusable()

      case let .loaded(showId):
        ShowView(showId: showId)
      }
    }
  }
}
