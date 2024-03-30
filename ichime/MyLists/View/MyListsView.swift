//
//  MyListsView.swift
//  ichime
//
//  Created by p.flaks on 20.01.2024.
//

import Combine
import ScraperAPI
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
}

@Observable
class MyListViewModel {
    private let apiClient: ScraperAPI.APIClient
    private let userManager: UserManager
    init(apiClient: ScraperAPI.APIClient = ApplicationDependency.container.resolve(),
         userManager: UserManager = ApplicationDependency.container.resolve())
    {
        self.apiClient = apiClient
        self.userManager = userManager
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

    func performInitialLoad() async {
        if !userManager.subscribed {
            return await updateState(.needSubscribe)
        }
        await updateState(.loading)
        await performUpdateState()
    }

    func performUpdateState() async {
        guard case let .isAuth(user) = userManager.state else {
            fatalError("This screen can use only with auth")
        }

        if !userManager.subscribed {
            return await updateState(.needSubscribe)
        }

        do {
            let categories = try await apiClient.sendAPIRequest(ScraperAPI.Request.GetWatchList(userId: user.id))
            if categories.isEmpty {
                return await updateState(.loadedButEmpty)
            }

            self.categories = categories
            return await updateState(.loaded(categories))
        } catch {
            await updateState(.loadingFailed(error))
        }
    }

    func performFilter(type: ScraperAPI.Types.ListCategoryType? = nil) async {
        if !userManager.subscribed {
            return await updateState(.needSubscribe)
        }

        guard let type else {
            return await updateState(.loaded(categories))
        }
        let filtered = categories.filter { $0.type == type }
        return await updateState(.loaded(filtered))
    }
}

struct MyListsView: View {
    @State private var viewModel: MyListViewModel = .init()
    @State private var categoryType: ScraperAPI.Types.ListCategoryType?

    var shareText: String {
        var categories = viewModel.categories
        if categoryType != nil {
            categories = viewModel.categories.filter { $0.type == categoryType }
        }

        return categories.map { category in
            let textShows = category.shows
                .map {
                    if let total = $0.episodes.total {
                        "- \($0.name.ru): \($0.episodes.watched) из \(total)"
                    } else {
                        "- \($0.name.ru): \($0.episodes.watched) из ??"
                    }
                }
                .joined(separator: "\n")

            return "\(category.type.rawValue):\n\(textShows)"
        }.joined(separator: "\n\n")
    }

    var body: some View {
        ToolbarWrapper(categoryType: $categoryType, shareText: shareText) {
            switch viewModel.state {
            case .idle:
                Color.clear.onAppear {
                    Task {
                        await self.viewModel.performInitialLoad()
                    }
                }
            case .loading:
                ProgressView()
                #if os(tvOS)
                    .focusable()
                #endif

            case .needSubscribe:
                ContentUnavailableView {
                    Label("Нужна подписка", systemImage: "person.fill.badge.plus")
                } description: {
                    Text("Подпишись чтоб получить все возможности приложения")
                }
                #if !os(tvOS)
                .textSelection(.enabled)
                #endif
            case let .loadingFailed(error):
                ContentUnavailableView {
                    Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error.localizedDescription)
                }
                #if !os(tvOS)
                .textSelection(.enabled)
                #endif
            case .loadedButEmpty:
                ContentUnavailableView {
                    Label("Ничего не нашлось", systemImage: "list.bullet")
                } description: {
                    Text("Вы еще ничего не добавили в свой список")
                }
            case let .loaded(categories):
                AnimeList(categories: categories) {
                    await viewModel.performUpdateState()
                }
            }
        }
        .onChange(of: categoryType) {
            Task {
                await viewModel.performFilter(type: categoryType)
            }
        }
        .task {
            switch viewModel.state {
            case .loaded, .loadedButEmpty, .loadingFailed, .needSubscribe:
                await viewModel.performUpdateState()
                await viewModel.performFilter(type: categoryType)
            case .idle, .loading:
                return
            }
        }
        .refreshable {
            await viewModel.performUpdateState()
            await viewModel.performFilter(type: categoryType)
        }
        #if !os(tvOS)
        .navigationTitle("Мой список")
        #endif
    }
}

struct ToolbarWrapper<Content: View>: View {
    @Binding var categoryType: ScraperAPI.Types.ListCategoryType?
    let shareText: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
        #if !os(tvOS)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink(item: shareText) {
                        Label("Поделиться", systemImage: "square.and.arrow.up")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Section {
                            Picker(selection: self.$categoryType, label: Text("Управление списком")) {
                                ForEach(ScraperAPI.Types.ListCategoryType.allCases, id: \.rawValue) { category in
                                    Label(category.rawValue, systemImage: category.imageInDropdown)
                                        .tag(category as ScraperAPI.Types.ListCategoryType?)
                                }
                            }
                        }

                        if self.categoryType != nil {
                            Button(role: .destructive) {
                                self.categoryType = nil
                            } label: {
                                Label("Сбросить", systemImage: "delete.forward")
                            }
                        }
                    } label: {
                        Label(
                            "Управлять списком",
                            systemImage: self.categoryType?.imageInToolbar ?? "list.bullet.circle"
                        )
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    ProfileButton()
                }
            }
        #endif
    }
}

#Preview {
    NavigationStack {
        MyListsView()
    }
}
