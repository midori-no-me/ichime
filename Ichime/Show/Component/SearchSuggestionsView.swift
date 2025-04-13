import SwiftUI

@Observable
private class SearchSuggestionsViewModel {
  enum State {
    case idle
    case loading
    case loaded((genres: [Genre], studios: [Studio]))
  }

  private var _state: State = .idle
  private let showSearchService: ShowSearchService

  private(set) var state: State {
    get {
      self._state
    }
    set {
      withAnimation {
        self._state = newValue
      }
    }
  }

  init(
    showSearchService: ShowSearchService = ApplicationDependency.container.resolve()
  ) {
    self.showSearchService = showSearchService
  }

  func performInitialLoading() async {
    self.state = .loading

    let (genres, studios) = await showSearchService.getAllGenresAndStudios()

    self.state = .loaded((genres: genres, studios: studios))
  }
}

struct SearchSuggestionsView: View {
  @State private var viewModel: SearchSuggestionsViewModel = .init()

  var body: some View {
    Group {
      switch self.viewModel.state {
      case .idle:
        Color.clear
          .onAppear {
            Task {
              await self.viewModel.performInitialLoading()
            }
          }

      case .loading:
        Color.clear

      case let .loaded((genres, studios)):
        VStack(alignment: .leading, spacing: 64) {
          if !genres.isEmpty {
            SectionWithCards(title: "Жанры") {
              ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 32) {
                  ForEach(genres) { genre in
                    GenreCard(id: genre.id, title: genre.title)
                  }
                }
              }
              .scrollClipDisabled()
            }
          }

          if !studios.isEmpty {
            SectionWithCards(title: "Студии") {
              ScrollView(.horizontal) {
                LazyHStack(alignment: .top) {
                  ForEach(studios) { studio in
                    StudioCard(
                      id: studio.id,
                      title: studio.name,
                      cover: studio.image
                    )
                    .frame(width: 300, height: 300)
                  }
                }
              }
              .scrollClipDisabled()
            }
          }
        }
      }
    }
  }
}
