import OrderedCollections
import SwiftUI

@Observable
private class ShowMomentsSectionViewModel {
  var moments: OrderedSet<Moment> = .init()

  private var page: Int = 1
  private var stopLazyLoading: Bool = false

  private let momentService: MomentService

  init(
    momentService: MomentService = ApplicationDependency.container.resolve()
  ) {
    self.momentService = momentService
  }

  func performInitialLoad(preloadedMoments: OrderedSet<Moment>) {
    if !self.moments.isEmpty {
      return
    }

    self.moments = preloadedMoments
    self.page += 1
  }

  func performLazyLoading(showId: Int) async {
    if self.stopLazyLoading {
      return
    }

    do {
      let moments = try await momentService.getShowMoments(showId: showId, page: self.page)

      if moments.last?.id == self.moments.last?.id {
        self.stopLazyLoading = true
        return
      }

      self.page += 1
      self.moments.append(contentsOf: moments)
    }
    catch {
      self.stopLazyLoading = true
    }
  }
}

struct ShowMomentsSection: View {
  let showId: Int
  let preloadedMoments: OrderedSet<Moment>

  @State private var viewModel: ShowMomentsSectionViewModel = .init()

  var body: some View {
    VStack(alignment: .leading) {
      SectionWithCards(title: "Моменты") {
        ScrollView(.horizontal) {
          LazyHStack(alignment: .top) {
            ForEach(self.viewModel.moments) { moment in
              MomentCard(moment: moment, displayShowTitle: false)
                .containerRelativeFrame(.horizontal, count: 4, span: 1, spacing: 64)
                .task {
                  if moment == self.viewModel.moments.last {
                    await self.viewModel.performLazyLoading(showId: self.showId)
                  }
                }
            }
          }
        }
        .scrollClipDisabled()
      }
    }
    .onAppear {
      self.viewModel.performInitialLoad(preloadedMoments: self.preloadedMoments)
    }
  }
}
