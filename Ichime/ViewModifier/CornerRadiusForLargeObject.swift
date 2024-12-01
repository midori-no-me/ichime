import Foundation
import SwiftUI

private struct CorderRadiusForLargeObject: ViewModifier {
  func body(content: Content) -> some View {
    content
      .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
  }
}

extension View {
  func cornerRadiusForLargeObject() -> some View {
    modifier(CorderRadiusForLargeObject())
  }
}
