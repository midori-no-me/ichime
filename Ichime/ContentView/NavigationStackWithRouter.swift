import SwiftUI

@MainActor @preconcurrency struct NavigationStackWithRouter<Root>: View where Root: View {
  @State private var path: [Route] = []

  private let root: () -> Root

  @MainActor @preconcurrency init(@ViewBuilder root: @escaping () -> Root) {
    self.root = root
  }

  var body: some View {
    NavigationStack(path: self.$path) {
      self.root()
        .navigationDestination(for: Route.self) { route in
          switch route {
          case let .showByMyAnimeListId(id):
            ShowByMyAnimeListIdView(myAnimeListId: id)

          case let .episode(id):
            EpisodeTranslationListView(episodeId: id)
          }
        }
        .onOpenURL { url in
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

            guard let myAnimeListId = Int(idParam) else {
              return
            }

            self.path.append(.showByMyAnimeListId(myAnimeListId))

          case "episode":
            let idParam = components.queryItems?.first { $0.name == "id" }?.value

            guard let idParam else {
              return
            }

            guard let episodeId = Int(idParam) else {
              return
            }

            self.path.append(.episode(episodeId))

          default:
            return
          }
        }
    }
  }
}
