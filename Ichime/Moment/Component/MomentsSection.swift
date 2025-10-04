import OSLog
import OrderedCollections
import SwiftUI

@Observable @MainActor
private final class MomentsSectionViewModel {
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
  private let sorting: MomentSorting

  init(
    momentService: MomentService = ApplicationDependency.container.resolve(),
    logger: Logger = .init(subsystem: ServiceLocator.applicationId, category: "MomentsSectionViewModel"),
    sorting: MomentSorting
  ) {
    self.momentService = momentService
    self.logger = logger
    self.sorting = sorting
  }

  func performInitialLoading() async {
    self.updateState(.loading)

    do {
      let moments = try await momentService.getMoments(
        page: 1,
        sorting: self.sorting
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
      let moments = try await momentService.getMoments(
        page: page + 1,
        sorting: self.sorting
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

struct MomentsSection: View {
  @State private var viewModel: MomentsSectionViewModel

  private let sorting: MomentSorting

  private init(
    viewModel: MomentsSectionViewModel,
    sorting: MomentSorting
  ) {
    self.viewModel = viewModel
    self.sorting = sorting
  }

  var body: some View {
    SectionWithCards(title: self.sorting == .popular ? "Популярные моменты" : "Моменты") {
      ScrollView(.horizontal) {
        switch self.viewModel.state {
        case .idle:
          MomentCardHStackInteractiveSkeleton(isCompact: false)
            .onAppear {
              Task {
                await self.viewModel.performInitialLoading()
              }
            }

        case .loading:
          MomentCardHStackInteractiveSkeleton(isCompact: false)

        case let .loadingFailed(error):
          MomentCardHStackContentUnavailable(isCompact: false) {
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
          MomentCardHStackContentUnavailable(isCompact: false) {
            Label("Пусто", systemImage: "rectangle.on.rectangle.angled")
          } description: {
            Text("Ничего не нашлось")
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
            isCompact: false,
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

  public static func withRandomSorting() -> Self {
    let momentSorting: MomentSorting =
      Int.random(in: 1...100) <= 10
      ? .popular
      : .newest

    return .init(
      viewModel: .init(sorting: momentSorting),
      sorting: momentSorting
    )
  }
}
