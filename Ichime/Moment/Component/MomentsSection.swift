import SwiftUI

@Observable
private class MomentsSectionViewModel {
  public var moments: [Moment] = []

  private var page: Int = 1
  private var stopLazyLoading: Bool = false

  private let momentService: MomentService

  init(
    momentService: MomentService = ApplicationDependency.container.resolve()
  ) {
    self.momentService = momentService
  }

  func performInitialLoad(preloadedMoments: [Moment]) {
    if !self.moments.isEmpty {
      return
    }

    self.moments = preloadedMoments
    self.page += 1
  }

  func performLazyLoading() async {
    if self.stopLazyLoading {
      return
    }

    do {
      let moments = try await momentService.getMoments(page: self.page)

      if moments.last?.id == self.moments.last?.id {
        self.stopLazyLoading = true
        return
      }

      self.page += 1
      self.moments += moments
    }
    catch {
      self.stopLazyLoading = true
    }
  }
}

struct MomentsSection: View {
  let preloadedMoments: [Moment]

  @State private var viewModel: MomentsSectionViewModel = .init()

  var body: some View {
    VStack(alignment: .leading) {
      SectionWithCards(title: "Моменты") {
        ScrollView(.horizontal) {
          LazyHStack(alignment: .top) {
            ForEach(self.viewModel.moments) { moment in
              MomentCard(moment: moment, displayShowTitle: true)
                .containerRelativeFrame(.horizontal, count: 3, span: 1, spacing: 64)
                .task {
                  if moment == self.viewModel.moments.last {
                    await self.viewModel.performLazyLoading()
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
