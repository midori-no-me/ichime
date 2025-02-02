import SwiftUI

struct MomentCard: View {
  static let RECOMMENDED_MINIMUM_WIDTH: CGFloat = 500

  static let RECOMMENDED_SPACING: CGFloat = 60

  let title: String
  let cover: URL
  let action: () -> Void

  var body: some View {
    MomentCardTv(
      title: self.title,
      cover: self.cover,
      action: self.action
    )
  }
}

private struct MomentCardTv: View {
  private static let CARD_WIDTH: CGFloat = 350
  private static let CARD_HEIGHT: CGFloat = 250

  let title: String
  let cover: URL
  let action: () -> Void

  var body: some View {
    Button(action: self.action) {
      AsyncImage(
        url: self.cover,
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

      Text(self.title)
        .lineLimit(2, reservesSpace: true)
        .truncationMode(.tail)
    }
    .frame(
      maxWidth: Self.CARD_WIDTH,
      maxHeight: Self.CARD_HEIGHT,
      alignment: .bottom
    )
    .buttonStyle(.borderless)
  }
}

private struct ImagePlaceholder: View {
  var body: some View {
    Image(systemName: "photo")
      .resizable()
      .aspectRatio(contentMode: .fit)
  }
}

#Preview {
  MomentCard(
    title: "Воздушный поцелуй",
    cover: URL(string: "https://anime365.ru/moments/thumbnail/219167.320x180.jpg?5")!,
    action: {}
  )
}
