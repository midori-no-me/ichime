import ScraperAPI
import SwiftData
import SwiftUI

@Observable
class MyListsSelectorViewModel {
  private let userManager: UserManager
  private let userAnimeListCache: UserAnimeListCache

  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded
    case needSubscribe
  }

  private(set) var state = State.idle

  init(
    userManager: UserManager = ApplicationDependency.container.resolve(),
    userAnimeListCache: UserAnimeListCache = ApplicationDependency.container.resolve()
  ) {
    self.userManager = userManager
    self.userAnimeListCache = userAnimeListCache
  }

  @MainActor
  private func updateState(_ newState: State) {
    state = newState
  }

  func performLoad() async {
    if !userManager.subscribed {
      return await updateState(.needSubscribe)
    }

    // Проверяем есть ли данные в базе
    let isEmpty = await userAnimeListCache.isCategoriesEmpty()
    if !isEmpty {
      await updateState(.loaded)
      // Обновляем данные в фоне
      Task {
        await loadFromAPI()
      }
      return
    }

    await updateState(.loading)
    await loadFromAPI()
  }

  private func loadFromAPI() async {
    await userAnimeListCache.cacheCategories()

    if await userAnimeListCache.isCategoriesEmpty() {
      return await updateState(.loadedButEmpty)
    }

    return await updateState(.loaded)
  }
}

struct MyListsSelectorView: View {
  @State private var viewModel: MyListsSelectorViewModel = .init()

  var body: some View {
    Group {
      switch viewModel.state {
      case .idle:
        Color.clear.onAppear {
          Task {
            await viewModel.performLoad()
          }
        }

      case .loading:
        ProgressView()
          .focusable()

      case .needSubscribe:
        ContentUnavailableView {
          Label("Нужна подписка", systemImage: "person.fill.badge.plus")
        } description: {
          Text("Подпишись чтоб получить все возможности приложения")
        }
        .focusable()

      case let .loadingFailed(error):
        ContentUnavailableView {
          Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
        } description: {
          Text(error.localizedDescription)
        }
        .focusable()

      case .loadedButEmpty:
        ContentUnavailableView {
          Label("Ничего не нашлось", systemImage: "list.bullet")
        } description: {
          Text("Вы еще ничего не добавили в свой список")
        }
        .focusable()

      case .loaded:
        List {
          ForEach(AnimeWatchStatus.allCases, id: \.rawValue) { status in
            NavigationLink(destination: {
              MyListsView(status: status)
            }) {
              Label(
                status.title,
                systemImage: status.imageInToolbarNotFilled
              )
            }
          }
        }
        .listStyle(.grouped)
      }
    }
    .refreshable {
      await viewModel.performLoad()
    }
  }
}
