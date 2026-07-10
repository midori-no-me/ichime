import IchimeShow
import OrderedCollections
import SwiftUI

@Observable @MainActor
private final class StaffMemberCardsSectionViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded(OrderedSet<StaffMember>)
  }

  private(set) var state: State = .idle

  private let showService: ShowService
  private let myAnimeListID: Int

  init(
    showService: ShowService = AppDependencies.live.showService,
    myAnimeListID: Int
  ) {
    self.showService = showService
    self.myAnimeListID = myAnimeListID
  }

  func performInitialLoading() async {
    self.updateState(.loading)

    do {
      let staffMembers = try await showService.getStaffMembers(
        myAnimeListID: self.myAnimeListID
      )

      if staffMembers.isEmpty {
        self.updateState(.loadedButEmpty)
      }
      else {
        self.updateState(.loaded(staffMembers))
      }
    }
    catch {
      self.updateState(.loadingFailed(error))
    }
  }

  private func updateState(_ state: State) {
    withAnimation(.default.speed(0.5)) {
      self.state = state
    }
  }
}

struct StaffMemberCardsSection: View {
  @State private var viewModel: StaffMemberCardsSectionViewModel

  init(myAnimeListID: Int) {
    self.viewModel = .init(myAnimeListID: myAnimeListID)
  }

  var body: some View {
    SectionWithCards(title: "Создатели") {
      ScrollView(.horizontal) {
        switch self.viewModel.state {
        case .idle:
          CircularPortraitHStackInteractiveSkeleton()
            .onAppear {
              Task {
                await self.viewModel.performInitialLoading()
              }
            }

        case .loading:
          CircularPortraitHStackInteractiveSkeleton()

        case let .loadingFailed(error):
          CircularPortraitHStackContentUnavailable {
            Label("Ошибка при загрузке", systemImage: "exclamationmark.triangle")
          } description: {
            Text(error.localizedDescription)
          } actions: {
            Button(action: {
              Task {
                await self.viewModel.performInitialLoading()
              }
            }) {
              Text("Обновить")
            }
          }

        case .loadedButEmpty:
          CircularPortraitHStackContentUnavailable {
            Label("Пусто", systemImage: "person.2")
          } description: {
            Text("У этого тайтла ещё нет информации об авторах")
          } actions: {
            Button(action: {
              Task {
                await self.viewModel.performInitialLoading()
              }
            }) {
              Text("Обновить")
            }
          }

        case let .loaded(staffMembers):
          CircularPortraitHStack(
            cards: staffMembers.elements,
            loadMore: nil
          ) { staffMember in
            StaffMemberCard(staffMember: staffMember)
          }
        }
      }
      .scrollClipDisabled()
    }
  }
}
