import OSLog
import OrderedCollections
import SwiftUI

@Observable @MainActor
private final class RelatedShowsSectionViewModel {
  enum State {
    case idle
    case loading
    case loadingFailed(Error)
    case loadedButEmpty
    case loaded(OrderedSet<GroupedRelatedShows>)
  }

  private(set) var state: State = .idle

  private let showService: ShowService
  private let myAnimeListId: Int

  init(
    showService: ShowService = ApplicationDependency.container.resolve(),
    myAnimeListId: Int
  ) {
    self.showService = showService
    self.myAnimeListId = myAnimeListId
  }

  func performInitialLoading() async {
    self.updateState(.loading)

    do {
      let shows = try await showService.getRelatedShows(
        myAnimeListId: self.myAnimeListId
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
  @State private var viewModel: RelatedShowsSectionViewModel

  init(myAnimeListId: Int) {
    self.viewModel = .init(myAnimeListId: myAnimeListId)
  }

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
#if os(tvOS)
    .focusSection()
    #endif
    .scrollClipDisabled()
    .scrollIndicators(.hidden)
  }
}
