import SwiftData
import SwiftUI

@main
struct IchimeApp: App {
  private let dependencies: AppDependencies = .live

  var body: some Scene {
    WindowGroup {
      AuthenticatedUserWrapperView {
        ContentView()
      }
      .environment(\.dependencies, self.dependencies)
    }
  }
}
