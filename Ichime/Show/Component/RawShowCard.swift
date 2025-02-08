import SwiftUI

struct RawShowCard: View {
  static let RECOMMENDED_MINIMUM_WIDTH: CGFloat = IMAGE_WIDTH * 3
  static let RECOMMENDED_SPACING: CGFloat = 60

  private static let IMAGE_WIDTH: CGFloat = 250

  private static let IMAGE_HEIGHT: CGFloat = IMAGE_WIDTH * 1.35
  private static let SPACING_BETWEEN_IMAGE_AND_CONTENT: CGFloat = 50

  let metadataLineComponents: [String]
  let cover: URL?
  let primaryTitle: String
  let secondaryTitle: String?

  var body: some View {
    HStack(
      alignment: .top,
      spacing: Self.SPACING_BETWEEN_IMAGE_AND_CONTENT
    ) {
      Group {
        if let cover {
          AsyncImage(
            url: cover,
            transaction: .init(animation: .easeInOut(duration: IMAGE_FADE_IN_DURATION))
          ) { phase in
            switch phase {
            case .empty:
              EmptyView()

            case let .success(image):
              image
                .resizable()
                .scaledToFit()

            case .failure:
              ImagePlaceholder()

            @unknown default:
              EmptyView()
            }
          }
        }
        else {
          ImagePlaceholder()
        }
      }
      .frame(
        width: Self.IMAGE_WIDTH,
        height: Self.IMAGE_HEIGHT,
        alignment: .top
      )

      VStack(alignment: .leading, spacing: 4) {
        if !self.metadataLineComponents.isEmpty {
          Text(self.metadataLineComponents.joined(separator: " • "))
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.secondary)
        }

        Text(self.primaryTitle)
          .font(.callout)
          .fontWeight(.medium)

        if let secondaryTitle {
          Text(secondaryTitle)
            .font(.caption)
            .foregroundStyle(Color.secondary)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.vertical, 4)
    }
    .contentShape(Rectangle())  // fixes hitbox of NavigationLink
  }
}

private struct ImagePlaceholder: View {
  var body: some View {
    Image(systemName: "photo")
      .resizable()
      .aspectRatio(contentMode: .fit)
  }
}

//
//#Preview {
//    NavigationStack {
//        OngoingsView()
//    }
//}
