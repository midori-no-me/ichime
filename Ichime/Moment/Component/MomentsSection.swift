import OrderedCollections
import SwiftUI

@Observable
private class MomentsSectionViewModel {
  var moments: OrderedSet<Moment> = []

  private var page: Int = 1
  private var stopLazyLoading: Bool = false

  private let momentService: MomentService

  init(
    momentService: MomentService = ApplicationDependency.container.resolve()
  ) {
    self.momentService = momentService
  }

  func performInitialLoad(preloadedMoments: OrderedSet<Moment>, sorting: MomentSorting) {
    if !self.moments.isEmpty {
      return
    }

    self.moments = preloadedMoments
    self.page += 1
  }

  func performLazyLoading(sorting: MomentSorting) async {
    if self.stopLazyLoading {
      return
    }

    do {
      let moments = try await momentService.getMoments(page: self.page, sorting: sorting)

      if moments.last?.id == self.moments.last?.id {
        self.stopLazyLoading = true
        return
      }

      self.page += 1
      self.moments = .init(self.moments.elements + moments)
    }
    catch {
      self.stopLazyLoading = true
    }
  }
}

struct MomentsSection: View {
  let preloadedMoments: OrderedSet<Moment>
  let sorting: MomentSorting

  @State private var viewModel: MomentsSectionViewModel = .init()

  var body: some View {
    VStack(alignment: .leading) {
      SectionWithCards(title: self.sectionTitle()) {
        ScrollView(.horizontal) {
          LazyHStack(alignment: .top) {
            ForEach(self.viewModel.moments) { moment in
              MomentCard(moment: moment, displayShowTitle: true)
                .containerRelativeFrame(.horizontal, count: 3, span: 1, spacing: 64)
                .task {
                  if moment == self.viewModel.moments.last {
                    await self.viewModel.performLazyLoading(sorting: self.sorting)
                  }
                }
            }
          }
        }
        .scrollClipDisabled()
      }
    }
    .onAppear {
      self.viewModel.performInitialLoad(preloadedMoments: self.preloadedMoments, sorting: self.sorting)
    }
  }

  private func sectionTitle() -> String {
    switch self.sorting {
    case .newest:
      "Моменты"
    case .popular:
      "Популярные моменты"
    }
  }
}
