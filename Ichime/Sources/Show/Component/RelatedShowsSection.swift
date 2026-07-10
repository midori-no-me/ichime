import IchimeShow
import OSLog
import OrderedCollections
import SwiftUI

@Observable @MainActor
private final class RelatedShowsSectionViewModel {
  // MARK: Nested Types

  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded(OrderedSet<GroupedRelatedShows>)
  }

  // MARK: Properties

  private(set) var state: State = .idle

  private let showService: ShowService
  private let myAnimeListID: Int

  // MARK: Lifecycle

  init(
    showService: ShowService = AppDependencies.live.showService,
    myAnimeListID: Int
  ) {
    self.showService = showService
    self.myAnimeListID = myAnimeListID
  }

  // MARK: Functions

  func performInitialLoading() async {
    self.updateState(.loading)

    do {
      let shows = try await showService.getRelatedShows(
        myAnimeListID: self.myAnimeListID
      )

      if shows.isEmpty {
        self.updateState(.loadedButEmpty)
      }
      else {
        self.updateState(.loaded(shows))
      }
    }
    catch {
      self.updateState(.loadingFailed(error))
    }
  }

  private func updateState(_ state: State) {
    withAnimation(.default.speed(0.5)) {
      self.state = state
    }
  }
}

struct RelatedShowsSection: View {
  // MARK: SwiftUI Properties

  @State private var viewModel: RelatedShowsSectionViewModel

  // MARK: Lifecycle

  init(myAnimeListID: Int) {
    self.viewModel = .init(myAnimeListID: myAnimeListID)
  }

  // MARK: Content Properties

  var body: some View {
    ScrollView(.horizontal) {
      switch self.viewModel.state {
      case .idle:
        SectionWithCards(title: "Связанные тайтлы") {
          ShowCardHStackInteractiveSkeleton()
            .onAppear {
              Task {
                await self.viewModel.performInitialLoading()
              }
            }
        }

      case .loading:
        SectionWithCards(title: "Связанные тайтлы") {
          ShowCardHStackInteractiveSkeleton()
        }

      case let .loadingFailed(error):
        SectionWithCards(title: "Связанные тайтлы") {
          ShowCardHStackContentUnavailable {
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
        }

      case .loadedButEmpty:
        SectionWithCards(title: "Связанные тайтлы") {
          ShowCardHStackContentUnavailable {
            Label("Пусто", systemImage: "rectangle.portrait.on.rectangle.portrait.angled")
          } description: {
            Text("Нет связей с другими тайтлами")
          } actions: {
            Button(action: {
              Task {
                await self.viewModel.performInitialLoading()
              }
            }) {
              Text("Обновить")
            }
          }
        }

      case let .loaded(relatedShowsGroups):
        LazyHStack(alignment: .top, spacing: ShowCard.RECOMMENDED_SPACING) {
          ForEach(relatedShowsGroups) { relatedShowGroup in
            SectionWithCards(title: relatedShowGroup.relationKind.title) {
              ShowCardHStack(cards: relatedShowGroup.relatedShows.elements, loadMore: nil) { relatedShow in
                ShowCardMyAnimeList(show: relatedShow.preview, displaySeason: true)
              }
            }
          }
        }
      }
    }
    .focusSection()
    .scrollClipDisabled()
  }
}
