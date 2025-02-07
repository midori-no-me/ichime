import DITranquillity
import SwiftData
import SwiftUI

@main
struct IchimeApp: App {
  let container: ModelContainer = ApplicationDependency.container.resolve()

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
    .modelContainer(self.container)
  }
}
