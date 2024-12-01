import Foundation
import SwiftUI

private struct TopEdgePaddingForMenu: ViewModifier {
  func body(content: Content) -> some View {
    #if os(tvOS)
      content.padding(.top, 40)
    #else
      content
    #endif
  }
}

/// Consistent padding that prevents menu button from`TabView` to overlap with content. Should be used only on root views used inside `Tab`.
extension View {
  func topEdgePaddingForMenu() -> some View {
    modifier(TopEdgePaddingForMenu())
  }
}
