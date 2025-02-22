import SwiftUI

@Observable
private class HomeViewModel {
  enum State {
    case idle
    case loading
    case loaded(
      (
        ongoings: [ShowPreview],
        topScored: [ShowPreview],
        nextSeason: [ShowPreviewShikimori]
      )
    )
  }

  private(set) var state: State = .idle

  private let homeService: HomeService

  init(
    homeService: HomeService = ApplicationDependency.container.resolve()
  ) {
    self.homeService = homeService
  }

  func performInitialLoad() async {
    self.state = .loading

    let sections = await homeService.preloadHomeSections()

    self.state = .loaded(sections)
  }
}

struct HomeView: View {
  @State private var viewModel: HomeViewModel = .init()

  var body: some View {
    switch self.viewModel.state {
    case .idle:
      Color.clear.onAppear {
        Task {
          await self.viewModel.performInitialLoad()
        }
      }

    case .loading:
      ProgressView()
        .focusable()
        .centeredContentFix()

    case let .loaded(sections):
      ScrollView(.vertical) {
        VStack(alignment: .leading, spacing: 64) {
          if !sections.ongoings.isEmpty {
            OngoingsSection(preloadedShows: sections.ongoings)
          }

          if !sections.nextSeason.isEmpty {
            NextSeasonSection(preloadedShows: sections.nextSeason)
          }

          if !sections.topScored.isEmpty {
            TopScoredSection(preloadedShows: sections.topScored)
          }
        }
      }
    }
  }
}
