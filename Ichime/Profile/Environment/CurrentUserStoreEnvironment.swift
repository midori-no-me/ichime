import SwiftUI

struct CurrentUserStoreEnvironmentKey: @MainActor EnvironmentKey {
  @MainActor static let defaultValue: CurrentUserStore = .init()
}

extension EnvironmentValues {
  @MainActor
  var currentUserStore: CurrentUserStore {
    get { self[CurrentUserStoreEnvironmentKey.self] }
    set { self[CurrentUserStoreEnvironmentKey.self] = newValue }
  }
}
