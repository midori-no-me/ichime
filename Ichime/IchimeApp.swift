import DITranquillity
import SwiftData
import SwiftUI

@main
struct IchimeApp: App {
  var body: some Scene {
    WindowGroup {
      AuthenticatedUserWrapperView {
        ContentView()
          .onMoveCommand { direction in
            print("Move:", direction)
          }
      }
    }
  }
}
