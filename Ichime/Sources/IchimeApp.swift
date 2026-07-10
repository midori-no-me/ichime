import IchimeProfile
import SwiftData
import SwiftUI

@main
struct IchimeApp: App {
  // MARK: Properties

  private let dependencies: AppDependencies = .live

  // MARK: Computed Properties

  var body: some Scene {
    WindowGroup {
      AuthenticatedUserWrapperView {
        ContentView()
      }
      .environment(\.dependencies, self.dependencies)
    }
  }
}
