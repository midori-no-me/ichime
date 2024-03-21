import Foundation
import SwiftUI

private struct CorderRadiusForMediumObject: ViewModifier {
    func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }
}

extension View {
    func cornerRadiusForMediumObject() -> some View {
        modifier(CorderRadiusForMediumObject())
    }
}
