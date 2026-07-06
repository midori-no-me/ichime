import OSLog
import OrderedCollections
import SwiftUI

@Observable @MainActor
private final class ShowMomentsSectionViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded(moments: OrderedSet<Moment>, page: Int, hasMore: Bool)
  }

  private(set) var state: State = .idle

  private let momentService: MomentService
  private let logger: Logger
  private let showId: Int

  init(
    momentService: MomentService = ApplicationDependency.container.resolve(),
    logger: Logger = .init(subsystem: ServiceLocator.applicationId, category: "ShowMomentsSectionViewModel"),
    showId: Int
  ) {
    self.momentService = momentService
    self.logger = logger
    self.showId = showId
  }

  func performInitialLoading() async {
    self.updateState(.loading)

    do {
      let moments = try await momentService.getShowMoments(
        showId: self.showId,
        page: 1
      )

      if moments.isEmpty {
        self.updateState(.loadedButEmpty)
      }
      else {
        self.updateState(
          .loaded(
            moments: moments,
            page: 1,
            hasMore: true
          )
        )
      }
    }
    catch {
      self.updateState(.loadingFailed(error))
    }
  }

  func performLazyLoading() async {
    guard case let .loaded(alreadyLoadedMoments, page, hasMore) = state else {
      return
    }

    if !hasMore {
      return
    }

    do {
      let moments = try await momentService.getShowMoments(
        showId: self.showId,
        page: page + 1
      )

      self.updateState(
        .loaded(
          moments: .init(alreadyLoadedMoments.elements + moments),
          page: page + 1,
          hasMore: moments.last?.id != alreadyLoadedMoments.last?.id
        )
      )
    }
    catch {
      self.logger.debug("Stop lazy loading due to exception: \(error)")
    }
  }

  private func updateState(_ state: State) {
    withAnimation(.easeInOut(duration: 0.5)) {
      self.state = state
    }
  }
}

struct ShowMomentsSection: View {
  @State private var viewModel: ShowMomentsSectionViewModel

  init(showId: Int) {
    self.viewModel = .init(showId: showId)
  }

  var body: some View {
    SectionWithCards(title: "Моменты") {
      ScrollView(.horizontal) {
        switch self.viewModel.state {
        case .idle:
          MomentCardHStackInteractiveSkeleton(isCompact: true)
            .onAppear {
              Task {
                await self.viewModel.performInitialLoading()
              }
            }

        case .loading:
          MomentCardHStackInteractiveSkeleton(isCompact: true)

        case let .loadingFailed(error):
          MomentCardHStackContentUnavailable(isCompact: true) {
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
          MomentCardHStackContentUnavailable(isCompact: true) {
            Label("Пусто", systemImage: "rectangle.on.rectangle.angled")
          } description: {
            Text("У этого тайтла ещё нет моментов")
          } actions: {
            Button(action: {
              Task {
                await self.viewModel.performInitialLoading()
              }
            }) {
              Text("Обновить")
            }
          }

        case let .loaded(moments, _, _):
          MomentCardHStack(
            cards: moments.elements,
            isCompact: true,
            loadMore: { await self.viewModel.performLazyLoading() }
          ) { moment, isCompact in
            MomentCard(
              moment: moment,
              displayShowTitle: !isCompact
            )
          }
        }
      }
      .scrollClipDisabled()
    }
  }
}
