import SwiftUI

struct AuthenticatedUserWrapperView<Content: View>: View {
  @AppStorage(Anime365BaseURL.UserDefaultsKey.BASE_URL, store: Anime365BaseURL.getUserDefaults()) private
    var anime365BaseURL: URL = Anime365BaseURL.DEFAULT_BASE_URL

  @State private var currentUserStore: CurrentUserStore = .init()

  private let content: () -> Content

  private let authenticationManager: AuthenticationManager

  init(
    @ViewBuilder content: @escaping () -> Content,
    authenticationManager: AuthenticationManager = ApplicationDependency.container.resolve()
  ) {
    self.content = content
    self.authenticationManager = authenticationManager
  }

  var body: some View {
    self.content()
      .environment(\.currentUserStore, self.currentUserStore)
      .task {
        try? await self.authenticationManager.fetchCurrentUser(
          currentUserStore: self.currentUserStore,
          baseURL: self.anime365BaseURL
        )
      }
      .onChange(of: self.anime365BaseURL) { _, newValue in
        Task {
          try? await self.authenticationManager.fetchCurrentUser(
            currentUserStore: self.currentUserStore,
            baseURL: self.anime365BaseURL
          )
        }
      }
  }
}
