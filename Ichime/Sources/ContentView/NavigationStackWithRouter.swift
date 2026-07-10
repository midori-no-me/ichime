import SwiftUI

@MainActor struct NavigationStackWithRouter<Root>: View where Root: View {
  @State private var path: [Route] = []

  /// Видит ли пользователь текущий NavigationStackWithRouter
  ///
  /// В табах у нас по одному стеку на таб. Как только пользователь впервые открывает таб, он остается висеть в памяти.
  /// Если пользователь пройдется по всем табам, то они все будут висеть в памяти. И во всех табах будут срабатывать
  /// события типа `.onOpenURL`. С помощью этого стейта мы можем понять, какой именно стек сейчас активен, чтобы
  /// обрабатывать события только в нем.
  @State private var isNavigationStackVisible: Bool = false

  private let root: () -> Root

  @MainActor init(@ViewBuilder root: @escaping () -> Root) {
    self.root = root
  }

  var body: some View {
    NavigationStack(path: self.$path) {
      self.root()
        .onAppear {
          self.isNavigationStackVisible = true
        }
        .onDisappear {
          self.isNavigationStackVisible = false
        }
        .navigationDestination(for: Route.self) { route in
          switch route {
          case let .showByMyAnimeListID(id):
            ShowByMyAnimeListIDView(myAnimeListID: id, onOpened: nil)

          case let .episode(id):
            EpisodeTranslationListView(episodeID: id, showTitle: nil)
          }
        }
        .onOpenURL { url in
          if !self.isNavigationStackVisible {
            return
          }

          let components = URLComponents(string: url.absoluteString)

          guard let components else {
            return
          }

          switch components.host {
          case "showByMyAnimeListId":
            let idParam = components.queryItems?.first { $0.name == "id" }?.value

            guard let idParam else {
              return
            }

            guard let myAnimeListID = Int(idParam) else {
              return
            }

            self.path.append(.showByMyAnimeListID(myAnimeListID))

          case "episode":
            let idParam = components.queryItems?.first { $0.name == "id" }?.value

            guard let idParam else {
              return
            }

            guard let episodeID = Int(idParam) else {
              return
            }

            self.path.append(.episode(episodeID))

          default:
            return
          }
        }
    }
  }
}
