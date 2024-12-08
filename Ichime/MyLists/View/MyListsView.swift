//
//  MyListsView.swift
//  ichime
//
//  Created by p.flaks on 20.01.2024.
//

import Combine
import ScraperAPI
import SwiftData
import SwiftUI

extension ScraperAPI.Types.ListCategoryType {
  var imageInDropdown: String {
    switch self {
    case .planned: return "hourglass"
    case .watching: return "eye.fill"
    case .completed: return "checkmark"
    case .onHold: return "pause.fill"
    case .dropped: return "archivebox.fill"
    }
  }

  var imageInToolbar: String {
    switch self {
    case .planned: return "hourglass.circle.fill"
    case .watching: return "eye.circle.fill"
    case .completed: return "checkmark.circle.fill"
    case .onHold: return "pause.circle.fill"
    case .dropped: return "archivebox.circle.fill"
    }
  }

  var imageInToolbarNotFilled: String {
    switch self {
    case .planned: return "hourglass.circle"
    case .watching: return "eye.circle"
    case .completed: return "checkmark.circle"
    case .onHold: return "pause.circle"
    case .dropped: return "archivebox.circle"
    }
  }
}

@Observable
class MyListViewModel {
  private let apiClient: ScraperAPI.APIClient
  private let userManager: UserManager
  private let modelContext: ModelContext?

  init(
    apiClient: ScraperAPI.APIClient = ApplicationDependency.container.resolve(),
    userManager: UserManager = ApplicationDependency.container.resolve(),
    modelContext: ModelContext?
  ) {
    self.apiClient = apiClient
    self.userManager = userManager
    self.modelContext = modelContext
  }

  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded([ScraperAPI.Types.ListByCategory])
    case needSubscribe
  }

  private(set) var state = State.idle
  var selectedShow: ScraperAPI.Types.Show?

  var categories: [ScraperAPI.Types.ListByCategory] = []

  @MainActor
  private func updateState(_ newState: State) {
    state = newState
  }

  func performLoad(categoryType: ScraperAPI.Types.ListCategoryType?) async {
    if !userManager.subscribed {
      return await updateState(.needSubscribe)
    }

    await updateState(.loading)

    guard case let .isAuth(user) = userManager.state else {
      fatalError("This screen can use only with auth")
    }

    if !userManager.subscribed {
      return await updateState(.needSubscribe)
    }

    do {
      var categories = try await apiClient.sendAPIRequest(
        ScraperAPI.Request.GetWatchList(userId: user.id)
      )
      if categories.isEmpty {
        return await updateState(.loadedButEmpty)
      }

      // Сохраняем все шоу в SwiftData
      for category in categories {
        for show in category.shows {
          let status = ShowListStatusEntity(id: show.id, status: category.type)
          modelContext?.insert(status)
        }
      }

      // Сохраняем изменения
      try modelContext?.save()

      if let categoryType {
        categories = categories.filter { $0.type == categoryType }
      }

      return await updateState(.loaded(categories))
    }
    catch {
      await updateState(.loadingFailed(error))
    }
  }
}

struct MyListsView: View {
  let categoryType: ScraperAPI.Types.ListCategoryType?
  @State private var viewModel: MyListViewModel
  @State private var selectedCategory: ScraperAPI.Types.ListCategoryType?

  init(
    categoryType: ScraperAPI.Types.ListCategoryType?,
    modelContext: ModelContext?
  ) {
    self.init(
      categoryType: categoryType,
      viewModel: .init(modelContext: modelContext),
      selectedCategory: nil
    )
  }

  init(
    categoryType: ScraperAPI.Types.ListCategoryType?,
    viewModel: MyListViewModel,
    selectedCategory: ScraperAPI.Types.ListCategoryType?
  ) {
    self.categoryType = categoryType
    _viewModel = State(initialValue: viewModel)
    _selectedCategory = State(initialValue: selectedCategory)
  }

  var shareText: String {
    let categories = viewModel.categories

    return categories.map { category in
      let textShows = category.shows
        .map {
          if let total = $0.episodes.total {
            "- \($0.name.ru): \($0.episodes.watched) из \(total)"
          }
          else {
            "- \($0.name.ru): \($0.episodes.watched) из ??"
          }
        }
        .joined(separator: "\n")

      return "\(category.type.rawValue):\n\(textShows)"
    }.joined(separator: "\n\n")
  }

  var body: some View {
    ToolbarWrapper(categoryType: $selectedCategory, shareText: shareText) {
      switch viewModel.state {
      case .idle:
        Color.clear.onAppear {
          Task {
            await self.viewModel.performLoad(categoryType: categoryType)
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

      case let .loadingFailed(error):
        ContentUnavailableView {
          Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
        } description: {
          Text(error.localizedDescription)
        }

      case .loadedButEmpty:
        ContentUnavailableView {
          Label("Ничего не нашлось", systemImage: "list.bullet")
        } description: {
          Text("Вы еще ничего не добавили в свой список")
        }
      case let .loaded(categories):
        AnimeList(categories: categories) {
          await viewModel.performLoad(categoryType: categoryType)
        }
      }
    }
    .task {
      switch viewModel.state {
      case .loaded, .loadedButEmpty, .loadingFailed, .needSubscribe:
        await viewModel.performLoad(categoryType: categoryType)
      case .idle, .loading:
        return
      }
    }
    .refreshable {
      await viewModel.performLoad(categoryType: categoryType)
    }
  }
}

struct ToolbarWrapper<Content: View>: View {
  @Binding var categoryType: ScraperAPI.Types.ListCategoryType?
  let shareText: String
  @ViewBuilder var content: () -> Content

  var body: some View {
    content()

  }
}

#Preview {
  NavigationStack {
    MyListsView(categoryType: .watching, modelContext: nil)
  }
}
