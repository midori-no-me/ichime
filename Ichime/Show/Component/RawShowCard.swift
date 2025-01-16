import SwiftUI

struct RawShowCard: View {
  private static let IMAGE_WIDTH: CGFloat = 250

  private static let IMAGE_HEIGHT: CGFloat = IMAGE_WIDTH * 1.35
  public static let RECOMMENDED_MINIMUM_WIDTH: CGFloat = IMAGE_WIDTH * 3
  public static let RECOMMENDED_SPACING: CGFloat = 60
  private static let SPACING_BETWEEN_IMAGE_AND_CONTENT: CGFloat = 50

  let metadataLineComponents: [String]
  let cover: URL?
  let primaryTitle: String
  let secondaryTitle: String?

  var body: some View {
    HStack(
      alignment: .top,
      spacing: RawShowCard.SPACING_BETWEEN_IMAGE_AND_CONTENT
    ) {
      Group {
        if let cover {
          AsyncImage(
            url: cover,
            transaction: .init(animation: .easeInOut(duration: 0.5))
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
        width: RawShowCard.IMAGE_WIDTH,
        height: RawShowCard.IMAGE_HEIGHT,
        alignment: .top
      )

      VStack(alignment: .leading, spacing: 4) {
        if !metadataLineComponents.isEmpty {
          Text(metadataLineComponents.joined(separator: " • "))
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.secondary)
        }

        Text(primaryTitle)
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
