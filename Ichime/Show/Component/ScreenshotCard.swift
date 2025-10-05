import OrderedCollections
import SwiftUI

struct ScreenshotCardRaw: View {
  static let RECOMMENDED_SPACING: CGFloat = 64
  static let RECOMMENDED_ASPECT_RATIO: CGSize = .init(width: 16, height: 9)
  static let RECOMMENDED_COUNT_PER_ROW: Int = 3

  let imageURL: URL?

  var body: some View {
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
          .scaledToFit()

      case .failure:
        ImagePlaceholder.color

      @unknown default:
        ImagePlaceholder.color
      }
    }
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity
    )
    .aspectRatio(Self.RECOMMENDED_ASPECT_RATIO, contentMode: .fit)
    .background(Color.black)
    .hoverEffect(.highlight)
  }

  static func placeholder() -> some View {
    Self.init(
      imageURL: nil
    )
    .redacted(reason: .placeholder)
  }
}

struct ScreenshotCard: View {
  let imageURL: URL?
  let onOpen: () -> Void

  var body: some View {
    Button(action: {
      self.onOpen()
    }) {
      ScreenshotCardRaw(imageURL: self.imageURL)
    }
    .buttonStyle(.borderless)
  }
}
