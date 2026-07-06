import Foundation
import SwiftUI

private struct RefreshOnAppear: ViewModifier {
  @State private var appearedOnce = false

  private let action: () -> Void

  init(
    action: @escaping () -> Void
  ) {
    self.action = action
  }

  func body(content: Content) -> some View {
    content
      .onAppear {
        if !self.appearedOnce {
          self.appearedOnce = true

          return
        }

        self.action()
      }
  }
}

/// Refreshes a view each time it appears. To prevent double-fetching data there is no refresh on first appearance.
extension View {
  func refreshOnAppear(_ action: @escaping () -> Void) -> some View {
    modifier(RefreshOnAppear(action: action))
  }
}
