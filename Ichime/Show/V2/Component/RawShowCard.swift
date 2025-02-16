import SwiftUI

struct RawShowCard: View {
  static let RECOMMENDED_SPACING: CGFloat = 64
  static let RECOMMENDED_HEIGHT: CGFloat = 384

  let metadataLineComponents: [String]
  let cover: URL?
  let primaryTitle: String
  let secondaryTitle: String?

  var body: some View {
    HStack(
      alignment: .top,
      spacing: 64
    ) {
      AsyncImage(
        url: self.cover,
        transaction: .init(animation: .easeInOut(duration: IMAGE_FADE_IN_DURATION))
      ) { phase in
        switch phase {
        case .empty:
          Color.clear

        case let .success(image):
          image
            .resizable()
            .scaledToFit()

        case .failure:
          ImagePlaceholder()

        @unknown default:
          Color.clear
        }
      }
      .frame(
        maxWidth: .infinity,
        maxHeight: .infinity,
        alignment: .top
      )
      .aspectRatio(425 / 600, contentMode: .fit)

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
      .padding(.vertical)
    }
  }
}

private struct ImagePlaceholder: View {
  var body: some View {
    Image(systemName: "photo")
      .resizable()
      .aspectRatio(contentMode: .fit)
  }
}

#Preview("Grid") {
  let image: (Int) -> URL? = { index in
    if index % 4 == 0 {
      // Small Landscape Image
      return URL(
        string:
          "https://cdn.myanimelist.net/r/84x124/images/characters/16/371204.jpg?s=527c14ef55a9df04ba10c32936d573d0"
      )!
    }
    else if index % 3 == 0 {
      // Landscape Image
      return URL(
        string: "https://cdn.myanimelist.net/s/common/uploaded_files/1734408527-daf48cfe8b3e252e7191d1cb9f139e94.png"
      )!
    }
    else if index % 2 == 0 {
      // Portrait Image
      return URL(string: "https://cdn.myanimelist.net/images/characters/7/525105.jpg")!
    }
    else {
      return nil
    }
  }

  NavigationStack {
    ScrollView(.vertical) {
      LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 64), count: 2), spacing: 64) {
        ForEach(0..<100) { index in
          RawShowCard(
            metadataLineComponents: [],
            cover: image(index + 1),
            primaryTitle: "Primary Title",
            secondaryTitle: "Secondary Title"
          )
          .frame(height: RawShowCard.RECOMMENDED_HEIGHT)
        }
      }
    }
    .background(Color.gray.ignoresSafeArea())
  }
}

#Preview("Horizontal Row") {
  let image: (Int) -> URL? = { index in
    if index % 4 == 0 {
      // Small Landscape Image
      return URL(
        string:
          "https://cdn.myanimelist.net/r/84x124/images/characters/16/371204.jpg?s=527c14ef55a9df04ba10c32936d573d0"
      )!
    }
    else if index % 3 == 0 {
      // Landscape Image
      return URL(
        string: "https://cdn.myanimelist.net/s/common/uploaded_files/1734408527-daf48cfe8b3e252e7191d1cb9f139e94.png"
      )!
    }
    else if index % 2 == 0 {
      // Portrait Image
      return URL(string: "https://cdn.myanimelist.net/images/characters/7/525105.jpg")!
    }
    else {
      return nil
    }
  }

  NavigationStack {
    ScrollView(.vertical) {
      ScrollView(.horizontal) {
        LazyHStack(alignment: .top, spacing: 64) {
          ForEach(0..<100) { index in
            RawShowCard(
              metadataLineComponents: [],
              cover: image(index + 1),
              primaryTitle: "Primary Title",
              secondaryTitle: "Secondary Title"
            )
            .frame(height: RawShowCard.RECOMMENDED_HEIGHT)
            .containerRelativeFrame(.horizontal, count: 2, span: 1, spacing: 64)
          }
        }
        .scrollClipDisabled()
      }
    }
    .background(Color.gray.ignoresSafeArea())
  }
}
