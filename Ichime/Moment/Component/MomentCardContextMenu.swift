import OSLog
import OrderedCollections
import SwiftUI

@Observable @MainActor
private final class MomentCardContextMenuViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loaded(MomentDetails)
  }

  private(set) var state: State = .idle

  private let momentService: MomentService
  private let momentId: Int

  init(
    momentService: MomentService = ApplicationDependency.container.resolve(),
    momentId: Int
  ) {
    self.momentService = momentService
    self.momentId = momentId
  }

  func performInitialLoading() async {
    self.updateState(.loading)

    do {
      let momentDetails = try await momentService.getMomentDetails(momentId: self.momentId)

      self.updateState(.loaded(momentDetails))
    }
    catch {
      self.updateState(.loadingFailed(error))
    }
  }

  private func updateState(_ state: State) {
    withAnimation(.easeInOut(duration: 0.5)) {
      self.state = state
    }
  }
}

struct MomentCardContextMenu: View {
  @State private var viewModel: MomentCardContextMenuViewModel

  init(
    momentId: Int
  ) {
    self.viewModel = .init(momentId: momentId)
  }

  var body: some View {
    switch self.viewModel.state {
    case .idle:
      Text("Загрузка...")
        .onAppear {
          Task {
            await self.viewModel.performInitialLoading()
          }
        }

    case .loading:
      Text("Загрузка...")

    case .loadingFailed(let error):
      Text(error.localizedDescription)

    case .loaded(let momentDetails):
      NavigationLink(destination: ShowView(showId: momentDetails.showId)) {
        Label(momentDetails.showTitle.getRomajiOrFullName(), systemImage: "info.circle")

        if let russian = momentDetails.showTitle.getRussian() {
          Text(russian)
        }
      }
    }
  }
}
