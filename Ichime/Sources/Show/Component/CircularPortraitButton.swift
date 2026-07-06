import Foundation
import SwiftUI

/// Кнопка с круглой картиной и текстом под ней
///
/// Подходит для портретов людей или персонажей.
struct CircularPortraitButton: View {
  static let RECOMMENDED_SPACING: CGFloat = 64
  static let RECOMMENDED_COUNT_PER_ROW: Int = 6

  private let imageUrl: URL?
  private let label: String
  private let secondaryLabel: String?

  private init(
    imageUrl: URL?,
    label: String,
    secondaryLabel: String?
  ) {
    self.imageUrl = imageUrl
    self.label = label
    self.secondaryLabel = secondaryLabel
  }

  var body: some View {
    Circle()
      .foregroundStyle(ImagePlaceholder.color)
      .overlay(
        AsyncImage(
          url: self.imageUrl,
          transaction: .init(animation: .easeInOut(duration: IMAGE_FADE_IN_DURATION))
        ) { phase in
          switch phase {
          case .empty:
            ImagePlaceholder.color

          case let .success(image):
            image
              .resizable()
              .scaledToFill()

          case .failure:
            ImagePlaceholder.color
              .overlay {
                Image(systemName: "person.fill")
                  .font(.title)
                  .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
              }

          @unknown default:
            ImagePlaceholder.color
          }
        },
        alignment: .top
      )
      .hoverEffect(.highlight)

    VStack {
      Text(self.label)
        .lineLimit(1)

      Text(self.secondaryLabel ?? "")
        .lineLimit(1, reservesSpace: true)
        .foregroundStyle(.secondary)
    }
  }

  static func placeholder() -> some View {
    Button(action: {}) {
      Self.init(
        imageUrl: nil,
        label: String(repeating: " ", count: 10),
        secondaryLabel: String(repeating: " ", count: 5),
      )
      .redacted(reason: .placeholder)
    }
    .buttonStyle(.borderless)
    .buttonBorderShape(.circle)
    .focusable(false)
  }

  static func interactivePlaceholder() -> some View {
    Button(action: {}) {
      Self.init(
        imageUrl: nil,
        label: String(repeating: " ", count: 10),
        secondaryLabel: String(repeating: " ", count: 5),
      )
      .redacted(reason: .placeholder)
    }
    .buttonStyle(.borderless)
    .buttonBorderShape(.circle)
  }

  static func button(
    imageUrl: URL?,
    label: String,
    secondaryLabel: String?,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Self.init(
        imageUrl: imageUrl,
        label: label,
        secondaryLabel: secondaryLabel,
      )
    }
    .buttonStyle(.borderless)
    .buttonBorderShape(.circle)
  }
}
