//
//  ShowView.swift
//  ichime
//
//  Created by p.flaks on 07.01.2024.
//

import SwiftUI

struct RawShowCard: View {
#if os(tvOS)
    public static let RECOMMENDED_MINIMUM_WIDTH: CGFloat = 500
#else
    public static let RECOMMENDED_MINIMUM_WIDTH: CGFloat = 300
#endif

#if os(tvOS)
    public static let RECOMMENDED_SPACING: CGFloat = 80
#else
    public static let RECOMMENDED_SPACING: CGFloat = 16
#endif

#if os(tvOS)
    private static let IMAGE_WIDTH: CGFloat = 200
    private static let IMAGE_HEIGHT: CGFloat = 270
#else
    private static let IMAGE_WIDTH: CGFloat = 100
    private static let IMAGE_HEIGHT: CGFloat = 135
#endif

#if os(tvOS)
    private static let SPACING_BETWEEN_IMAGE_AND_CONTENT: CGFloat = 20
#else
    private static let SPACING_BETWEEN_IMAGE_AND_CONTENT: CGFloat = 8
#endif

    let metadataLineComponents: [String]
    let cover: URL?
    let primaryTitle: String
    let secondaryTitle: String?

    var body: some View {
        HStack(alignment: .top, spacing: RawShowCard.SPACING_BETWEEN_IMAGE_AND_CONTENT) {
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
                            .cornerRadiusForMediumObject()
                            .clipped()

                    case .failure:
                        EmptyView()

                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(
                    width: RawShowCard.IMAGE_WIDTH,
                    height: RawShowCard.IMAGE_HEIGHT,
                    alignment: .top
                )
            }

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

    }
}

#Preview {
    NavigationStack {
        OngoingsView()
    }
}
