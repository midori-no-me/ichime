//
//  MomentCard.swift
//  Ichime
//
//  Created by p.flaks on 26.03.2024.
//

import SwiftUI

struct MomentCard: View {
  public static let RECOMMENDED_MINIMUM_WIDTH: CGFloat = 500

  public static let RECOMMENDED_SPACING: CGFloat = 60

  public let title: String
  public let cover: URL
  public let websiteUrl: URL
  public let id: Int
  public let action: () -> Void

  var body: some View {
    MomentCardTv(
      title: title,
      cover: cover,
      websiteUrl: websiteUrl,
      id: id,
      action: action
    )

  }
}

private struct MomentCardTv: View {
  public let title: String
  public let cover: URL
  public let websiteUrl: URL
  public let id: Int
  public let action: () -> Void

  private static let CARD_WIDTH: CGFloat = 350
  private static let CARD_HEIGHT: CGFloat = 250

  var body: some View {
    Button(action: action) {
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

      Text(title)
        .lineLimit(2, reservesSpace: true)
        .truncationMode(.tail)
    }
    .frame(
      maxWidth: MomentCardTv.CARD_WIDTH,
      maxHeight: MomentCardTv.CARD_HEIGHT,
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
    websiteUrl: URL(string: "https://anime365.ru/moments/219167")!,
    id: 219_167,
    action: {}
  )
}
