//
//  MyListEditView.swift
//  ani365
//
//  Created by Nikita Nafranets on 25.01.2024.
//

import ScraperAPI
import SwiftUI

class MyListEditViewModel: ObservableObject {
    private let client: ScraperClient
    init(apiClient: ScraperClient) {
        client = apiClient
    }

    enum State {
        case idle
        case loading
        case loadingFailed(Error)
        case loaded(ScraperAPI.Types.UserRate)
        case formSended
    }

    @Published private(set) var state = State.idle

    @MainActor
    private func updateState(_ newState: State) {
        state = newState
    }

    func performInitialLoad(_ showId: Int) async {
        await updateState(.loading)

        do {
            let userRate = try await client.api.sendAPIRequest(ScraperAPI.Request.GetUserRate(showId: showId))
            await updateState(.loaded(userRate))
        } catch {
            await updateState(.loadingFailed(error))
        }
    }

    func performUpdate(_ showId: Int, _ userRate: ScraperAPI.Types.UserRate) async {
        await updateState(.loading)

        do {
            let _ = try await client.api
                .sendAPIRequest(ScraperAPI.Request.UpdateUserRate(showId: showId, userRate: userRate))
            await updateState(.formSended)
        } catch {
            await updateState(.loadingFailed(error))
        }
    }

    func performDelete(_ showId: Int) async {
        await updateState(.loading)

        do {
            let _ = try await client.api.sendAPIRequest(ScraperAPI.Request.UpdateUserRate(
                showId: showId,
                userRate: .init(score: 0, currentEpisode: 0, status: .deleted, comment: "")
            ))
            await updateState(.formSended)
        } catch {
            await updateState(.loadingFailed(error))
        }
    }
}

struct MyListEditView: View {
    let show: ScraperAPI.Types.Show
    @ObservedObject var viewModel: MyListEditViewModel
    let onUpdate: () -> Void

    @Environment(\.dismiss) private var dismiss

    var totalEpisodes: String {
        show.episodes.total == Int.max ? "??" : String(show.episodes.total)
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle:
                Color.clear.onAppear {
                    Task {
                        await viewModel.performInitialLoad(show.id)
                    }
                }
            case .loading:
                ProgressView()
            case let .loadingFailed(error):
                ContentUnavailableView {
                    Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(error.localizedDescription)
                }
                .textSelection(.enabled)

            case let .loaded(userRate):
                UserRateForm(userRate, totalEpisodes: totalEpisodes) { newUserRate in
                    Task {
                        await viewModel.performUpdate(show.id, newUserRate)
                    }
                } onRemove: {
                    Task {
                        await viewModel.performDelete(show.id)
                    }
                }
            case .formSended:
                Color.clear.onAppear {
                    dismiss()
                    onUpdate()
                }
            }
        }
        .navigationTitle(show.name.ru)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Закрыть") {
                    self.dismiss()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        MyListEditView(
            show: ScraperAPI.Types.Show.sampleData,
            viewModel: .init(apiClient: .init(scraperClient: ServiceLocator.getScraperAPIClient())),
            onUpdate: {}
        )
    }
}
