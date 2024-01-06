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

class MyListViewModel: ObservableObject {
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

    @Published private(set) var state = State.idle
    @Published var selectedShow: ScraperAPI.Types.Show?

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

    var cancel: Cancellable?

    func performUpdateState() async {
        guard case let .isAuth(user) = userManager.state else {
            fatalError("This screen can use only with auth")
        }
        
        if !userManager.subscribed {
            return await updateState(.needSubscribe)
        }

        if let cancel {
            cancel.cancel()
            self.cancel = nil
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

    func selectShow(showId: Int?) {
        guard let showId else {
            selectedShow = nil
            return
        }

        for category in categories {
            for show in category.shows {
                if show.id == showId {
                    selectedShow = show
                }
            }
        }
    }
}

struct MyListsView: View {
    @StateObject private var viewModel: MyListViewModel = .init()
    @State private var categoryType: ScraperAPI.Types.ListCategoryType?
    @State private var selectedShowId: Int?

    var shareText: String {
        var categories = viewModel.categories
        if categoryType != nil {
            categories = viewModel.categories.filter { $0.type == categoryType }
        }

        return categories.map { category in
            let textShows = category.shows
                .map {
                    "— \($0.name.ru): \($0.episodes.watched) из \($0.episodes.total == Int.max ? "??" : String($0.episodes.total))"
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
            case .needSubscribe:
                ContentUnavailableView {
                    Label("Нужна подписка", systemImage: "person.fill.badge.plus")
                } description: {
                    Text("Подпишись чтоб получить все возможности приложения")
                }
                .textSelection(.enabled)
            case let .loadingFailed(error):
                ContentUnavailableView {
                    Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error.localizedDescription)
                }
                .textSelection(.enabled)
            case .loadedButEmpty:
                ContentUnavailableView {
                    Label("Ничего не нашлось", systemImage: "list.bullet")
                } description: {
                    Text("Вы еще ничего не добавили в свой список")
                }
            case let .loaded(categories):
                AnimeList(categories: categories, selectedShow: $selectedShowId)
            }
        }
        .onChange(of: categoryType) {
            Task {
                await viewModel.performFilter(type: categoryType)
            }
        }
        .onChange(of: selectedShowId) {
            viewModel.selectShow(showId: selectedShowId)
        }
        .sheet(item: $viewModel.selectedShow, onDismiss: {
            selectedShowId = nil
        }, content: { show in
            NavigationStack {
                MyListEditView(
                    show: show
                ) {
                    Task {
                        await viewModel.performUpdateState()
                    }
                }
            }
            .presentationDetents([.medium, .large])
        })
        .refreshable {
            await viewModel.performUpdateState()
            await viewModel.performFilter(type: categoryType)
        }
        .navigationTitle("Мой список")
    }
}

struct ToolbarWrapper<Content: View>: View {
    @Binding var categoryType: ScraperAPI.Types.ListCategoryType?
    let shareText: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
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
                    NavigationLink(destination: ProfileView()) {
                        Image(systemName: "person.circle")
                    }
                }
            }
    }
}

#Preview {
    NavigationStack {
        MyListsView()
    }
}
