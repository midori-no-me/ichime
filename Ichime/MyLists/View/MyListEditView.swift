import ScraperAPI
import SwiftData
import SwiftUI

@Observable
class MyListEditViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loaded(ScraperAPI.Types.UserRate)
    case formSended
  }

  private(set) var state: State = .idle

  private let client: ScraperAPI.APIClient
  private let userAnimeListManager: UserAnimeListManager

  init(
    apiClient: ScraperAPI.APIClient = ApplicationDependency.container.resolve(),
    container: ModelContainer = ApplicationDependency.container.resolve()
  ) {
    self.client = apiClient
    self.userAnimeListManager = .init(modelContainer: container)
  }

  func performInitialLoad(_ showId: Int) async {
    await self.updateState(.loading)

    do {
      let userRate = try await client.sendAPIRequest(ScraperAPI.Request.GetUserRate(showId: showId))
      await self.updateState(.loaded(userRate))
    }
    catch {
      await self.updateState(.loadingFailed(error))
    }
  }

  func performUpdate(_ showId: Int, _ userRate: ScraperAPI.Types.UserRate) async {
    await self.updateState(.loading)

    do {
      _ =
        try await self.client
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

      await self.userAnimeListManager.updateStatusById(id: showId, status: newStatus)
      await self.updateState(.formSended)
    }
    catch {
      await self.updateState(.loadingFailed(error))
    }
  }

  func performDelete(_ showId: Int) async {
    await self.updateState(.loading)

    do {
      _ = try await self.client.sendAPIRequest(
        ScraperAPI.Request.UpdateUserRate(
          showId: showId,
          userRate: .init(score: 0, currentEpisode: 0, status: .deleted, comment: "")
        )
      )
      await self.userAnimeListManager.remove(id: showId)
      await self.updateState(.formSended)
    }
    catch {
      await self.updateState(.loadingFailed(error))
    }
  }

  @MainActor
  private func updateState(_ newState: State) {
    self.state = newState
  }
}

struct MyListEditView: View {
  @State private var viewModel: MyListEditViewModel = .init()
  @Environment(\.dismiss) private var dismiss

  let show: MyListShow
  let onUpdate: (() -> Void)?

  var totalEpisodes: String {
    if let totalEpisodes = show.totalEpisodes {
      String(totalEpisodes)
    }
    else {
      "??"
    }
  }

  init(show: MyListShow) {
    self.show = show
    self.onUpdate = nil
  }

  init(show: MyListShow, onUpdate: @escaping () -> Void) {
    self.show = show
    self.onUpdate = onUpdate
  }

  var body: some View {
    NavigationStack {
      Group {
        switch self.viewModel.state {
        case .idle:
          Color.clear.onAppear {
            Task {
              await self.viewModel.performInitialLoad(self.show.id)
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
          .focusable()

        case let .loaded(userRate):
          UserRateForm(userRate, totalEpisodes: self.totalEpisodes) { newUserRate in
            Task {
              await self.viewModel.performUpdate(self.show.id, newUserRate)
            }
          } onRemove: {
            Task {
              await self.viewModel.performDelete(self.show.id)
            }
          }

        case .formSended:
          Color.clear.onAppear {
            self.dismiss()
            self.onUpdate?()
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
      .navigationTitle(self.show.name)

    }.presentationDetents([.medium, .large])
  }
}
