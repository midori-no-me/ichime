import SwiftUI

struct Chip {
  static let RECOMMENDED_SPACING: CGFloat = 4

  static func filled(label: String) -> some View {
    Text(label)
    #if os(tvOS)
      .font(.caption2)
    #else
      .font(.caption2.pointSize(9))
    #endif
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
    #if os(tvOS)
      .background(.ultraThickMaterial)
    #else
      .foregroundStyle(.foreground)
      .glassEffect()
    #endif
      .clipShape(.rect(cornerRadius: 8, style: .continuous))
  }

  static func outlined(label: String) -> some View {
    Text(label)
      .font(.caption2)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .clipShape(.rect(cornerRadius: 8, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 8)
          .strokeBorder(.secondary, lineWidth: 1)
      }
  }
}
