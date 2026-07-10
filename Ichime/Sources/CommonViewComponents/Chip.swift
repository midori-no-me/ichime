import SwiftUI

struct Chip {
  // MARK: Static Properties

  static let RECOMMENDED_SPACING: CGFloat = 4

  // MARK: Static Functions

  static func filled(label: String) -> some View {
    Text(label)
      .font(.caption2)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(.thickMaterial)
      .clipShape(.rect(cornerRadius: 8))
  }

  static func outlined(label: String) -> some View {
    Text(label)
      .font(.caption2)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .clipShape(.rect(cornerRadius: 8))
      .overlay {
        RoundedRectangle(cornerRadius: 8)
          .strokeBorder(.secondary, lineWidth: 1)
      }
  }
}
