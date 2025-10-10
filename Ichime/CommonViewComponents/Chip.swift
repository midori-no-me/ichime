import SwiftUI

struct Chip {
  static let RECOMMENDED_SPACING: CGFloat = 4

  static func filled(label: String) -> some View {
    Text(label)
      .font(.caption2)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(.ultraThickMaterial)
      .clipShape(RoundedRectangle(cornerRadius: 8))
  }
}
