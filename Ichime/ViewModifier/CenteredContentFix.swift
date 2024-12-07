import Foundation
import SwiftUI

private struct CenteredContentFix: ViewModifier {
  func body(content: Content) -> some View {
    content
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
  }
}

/// Prevents content from aligning to top-left corner if it was placed inside`TabView`. Should be used only on root views used inside `Tab`
@available(tvOS 18.0, *)
extension View {
  func centeredContentFix() -> some View {
    modifier(CenteredContentFix())
  }
}
