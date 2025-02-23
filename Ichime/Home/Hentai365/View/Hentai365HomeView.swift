import SwiftUI

@Observable
private class Hentai365HomeViewModel {
  enum State {
    case idle
    case loading
    case loaded(
      (
        topScored: [ShowPreview],
        years: [(shows: [ShowPreview], year: Int)]
      )
    )
  }

  private(set) var state: State = .idle

  private let homeService: Hentai365HomeService

  init(
    homeService: Hentai365HomeService = ServiceLocator.hentai365HomeService
  ) {
    self.homeService = homeService
  }

  func performInitialLoad() async {
    self.state = .loading

    let sections = await homeService.preloadHomeSections()

    self.state = .loaded(sections)
  }
}

struct Hentai365HomeView: View {
  @State private var viewModel: Hentai365HomeViewModel = .init()

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
          if !sections.topScored.isEmpty {
            Hentai365TopScoredSection(preloadedShows: sections.topScored)
          }

          ForEach(sections.years, id: \.year) { yearSection in
            if !yearSection.shows.isEmpty {
              Hentai365YearSection(preloadedShows: yearSection.shows, year: yearSection.year)
            }
          }
        }
      }
    }
  }
}
