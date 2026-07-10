import IchimeShow
import OrderedCollections
import SwiftUI

@Observable @MainActor
private final class SearchSuggestionsViewModel {
  // MARK: Nested Types

  enum State {
    case idle
    case loading
    case loaded((genres: OrderedSet<Genre>, studios: OrderedSet<Studio>))
  }

  // MARK: Properties

  private var _state: State = .idle
  private let showSearchService: ShowSearchService

  // MARK: Computed Properties

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

  // MARK: Lifecycle

  init(
    showSearchService: ShowSearchService = AppDependencies.live.showSearchService
  ) {
    self.showSearchService = showSearchService
  }

  // MARK: Functions

  func performInitialLoading() async {
    self.state = .loading

    let (genres, studios) = await showSearchService.getAllGenresAndStudios()

    self.state = .loaded((genres: genres, studios: studios))
  }
}

struct SearchSuggestionsView: View {
  // MARK: SwiftUI Properties

  @State private var viewModel: SearchSuggestionsViewModel = .init()

  // MARK: Content Properties

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
