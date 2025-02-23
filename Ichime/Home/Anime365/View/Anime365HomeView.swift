import SwiftUI

@Observable
private class Anime365HomeViewModel {
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

  private let homeService: Anime365HomeService

  init(
    homeService: Anime365HomeService = ApplicationDependency.container.resolve()
  ) {
    self.homeService = homeService
  }

  func performInitialLoad() async {
    self.state = .loading

    let sections = await homeService.preloadHomeSections()

    self.state = .loaded(sections)
  }
}

struct Anime365HomeView: View {
  @State private var viewModel: Anime365HomeViewModel = .init()

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
            Anime365OngoingsSection(preloadedShows: sections.ongoings)
          }

          if !sections.nextSeason.isEmpty {
            Anime365NextSeasonSection(preloadedShows: sections.nextSeason)
          }

          if !sections.topScored.isEmpty {
            Anime365TopScoredSection(preloadedShows: sections.topScored)
          }
        }
      }
    }
  }
}
