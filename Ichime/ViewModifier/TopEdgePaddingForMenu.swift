import Foundation
import SwiftUI

private struct TopEdgePaddingForMenu: ViewModifier {
  func body(content: Content) -> some View {
    content.padding(.top, 40)
  }
}

/// Consistent padding that prevents menu button from`TabView` to overlap with content. Should be used only on root views used inside `Tab`
@available(tvOS 18.0, *)
extension View {
  func topEdgePaddingForMenu() -> some View {
    modifier(TopEdgePaddingForMenu())
  }
}
