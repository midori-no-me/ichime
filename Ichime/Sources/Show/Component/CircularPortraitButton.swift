import Foundation
import SwiftUI

/// Кнопка с круглой картиной и текстом под ней
///
/// Подходит для портретов людей или персонажей.
struct CircularPortraitButton: View {
  // MARK: Static Properties

  static let RECOMMENDED_SPACING: CGFloat = 64
  static let RECOMMENDED_COUNT_PER_ROW: Int = 6

  // MARK: Properties

  private let imageURL: URL?
  private let label: String
  private let secondaryLabel: String?

  // MARK: Lifecycle

  private init(
    imageURL: URL?,
    label: String,
    secondaryLabel: String?
  ) {
    self.imageURL = imageURL
    self.label = label
    self.secondaryLabel = secondaryLabel
  }

  // MARK: Content Properties

  var body: some View {
    Circle()
      .foregroundStyle(ImagePlaceholder.color)
      .overlay(
        AsyncImage(
          url: self.imageURL,
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

  // MARK: Static Functions

  static func placeholder() -> some View {
    Button(action: {}) {
      Self.init(
        imageURL: nil,
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
        imageURL: nil,
        label: String(repeating: " ", count: 10),
        secondaryLabel: String(repeating: " ", count: 5),
      )
      .redacted(reason: .placeholder)
    }
    .buttonStyle(.borderless)
    .buttonBorderShape(.circle)
  }

  static func button(
    imageURL: URL?,
    label: String,
    secondaryLabel: String?,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      Self.init(
        imageURL: imageURL,
        label: label,
        secondaryLabel: secondaryLabel,
      )
    }
    .buttonStyle(.borderless)
    .buttonBorderShape(.circle)
  }
}
