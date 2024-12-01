import Foundation
import SwiftUI

private struct HorizontalScreenEdgePadding: ViewModifier {
  @Environment(\.horizontalSizeClass) var horizontalSizeClass

  func body(content: Content) -> some View {
    switch horizontalSizeClass {
    case .compact:
      content.padding(.horizontal, 16)

    case .regular:
      content.padding(.horizontal, 20)

    default:
      content  // no padding on tvOS cuz it has it out-of-the-box
    }
  }
}

/// Consistent padding that aligns with `.navigationTitle`. Should be used only on root views inside `ScrollView`.
extension View {
  func horizontalScreenEdgePadding() -> some View {
    modifier(HorizontalScreenEdgePadding())
  }
}
