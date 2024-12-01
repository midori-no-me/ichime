//
//  MyListEditView.swift
//  ichime
//
//  Created by Nikita Nafranets on 25.01.2024.
//

import ScraperAPI
import SwiftUI

@Observable
class MyListEditViewModel {
  private let client: ScraperAPI.APIClient
  init(apiClient: ScraperAPI.APIClient = ApplicationDependency.container.resolve()) {
    client = apiClient
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
      await updateState(.formSended)
    }
    catch {
      await updateState(.loadingFailed(error))
    }
  }
}

struct MyListEditView: View {
  let show: MyListShow
  let onUpdate: () -> Void

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
            #if os(tvOS)
              .focusable()
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
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Закрыть") {
            self.dismiss()
          }
        }
      }
      .navigationTitle(show.name)
      #if !os(tvOS)
        .navigationBarTitleDisplayMode(.inline)
      #endif
    }.presentationDetents([.medium, .large])
  }
}

#Preview {
  MyListEditView(
    show: .init(id: 21587, name: "Благословение небожителей", totalEpisodes: 11),
    onUpdate: {}
  )
}
