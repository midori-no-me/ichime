//
//  MyListEditView.swift
//  ichime
//
//  Created by Nikita Nafranets on 25.01.2024.
//

import ScraperAPI
import SwiftData
import SwiftUI

@Observable
class MyListEditViewModel {
  private let client: ScraperAPI.APIClient
  private let userAnimeListManager: UserAnimeListManager
  init(
    apiClient: ScraperAPI.APIClient = ApplicationDependency.container.resolve(),
    container: ModelContainer = ApplicationDependency.container.resolve()
  ) {
    client = apiClient
    userAnimeListManager = .init(modelContainer: container)
  }

  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loaded(ScraperAPI.Types.UserRate)
    case formSended
  }

  private(set) var state = State.idle

  @MainActor
  private func updateState(_ newState: State) {
    state = newState
  }

  func performInitialLoad(_ showId: Int) async {
    await updateState(.loading)

    do {
      let userRate = try await client.sendAPIRequest(ScraperAPI.Request.GetUserRate(showId: showId))
      await updateState(.loaded(userRate))
    }
    catch {
      await updateState(.loadingFailed(error))
    }
  }

  func performUpdate(_ showId: Int, _ userRate: ScraperAPI.Types.UserRate) async {
    await updateState(.loading)

    do {
      _ =
        try await client
        .sendAPIRequest(ScraperAPI.Request.UpdateUserRate(showId: showId, userRate: userRate))
      let newStatus: AnimeWatchStatus =
        switch userRate.status {
        case .onHold:
          .onHold
        case .planned:
          .planned
        case .watching:
          .watching
        case .dropped:
          .dropped
        default:
          .completed
        }

      await userAnimeListManager.updateStatusById(id: showId, status: newStatus)
      await updateState(.formSended)
    }
    catch {
      await updateState(.loadingFailed(error))
    }
  }

  func performDelete(_ showId: Int) async {
    await updateState(.loading)

    do {
      _ = try await client.sendAPIRequest(
        ScraperAPI.Request.UpdateUserRate(
          showId: showId,
          userRate: .init(score: 0, currentEpisode: 0, status: .deleted, comment: "")
        )
      )
      await userAnimeListManager.remove(id: showId)
      await updateState(.formSended)
    }
    catch {
      await updateState(.loadingFailed(error))
    }
  }
}

struct MyListEditView: View {
  let show: MyListShow
  let onUpdate: (() -> Void)?

  init(show: MyListShow) {
    self.show = show
    onUpdate = nil
  }

  init(show: MyListShow, onUpdate: @escaping () -> Void) {
    self.show = show
    self.onUpdate = onUpdate
  }

  @State private var viewModel: MyListEditViewModel = .init()
  @Environment(\.dismiss) private var dismiss

  var totalEpisodes: String {
    if let totalEpisodes = show.totalEpisodes {
      String(totalEpisodes)
    }
    else {
      "??"
    }
  }

  var body: some View {
    NavigationStack {
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
            .focusable()

        case let .loadingFailed(error):
          ContentUnavailableView {
            Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
          } description: {
            Text(error.localizedDescription)
          }

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
            onUpdate?()
          }
        }
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Закрыть") {
            self.dismiss()
          }
        }
      }
      .navigationTitle(show.name)

    }.presentationDetents([.medium, .large])
  }
}

#Preview {
  MyListEditView(
    show: .init(id: 21587, name: "Благословение небожителей", totalEpisodes: 11),
    onUpdate: {}
  )
}
