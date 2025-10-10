import SwiftUI

struct ShowCard: View {
  static let RECOMMENDED_ASPECT_RATIO: CGFloat = 0.7123
  static let RECOMMENDED_SPACING: CGFloat = 40
  static let RECOMMENDED_COUNT_PER_ROW: Int = 5

  @Environment(\.isFocused) private var isFocused
  @State private var title: String

  let topChips: [String]
  let bottomChips: [String]
  let cover: URL?
  let primaryTitle: String
  let secondaryTitle: String?

  init(
    topChips: [String],
    bottomChips: [String],
    cover: URL?,
    primaryTitle: String,
    secondaryTitle: String?
  ) {
    self.topChips = topChips
    self.bottomChips = bottomChips
    self.cover = cover
    self.primaryTitle = primaryTitle
    self.secondaryTitle = secondaryTitle
    self.title = primaryTitle
  }

  var body: some View {
    ZStack {
      Rectangle()
        .fill(
          LinearGradient(
            gradient: .init(colors: [.clear, .clear, .black.opacity(0.75)]),
            startPoint: .center,
            endPoint: .bottom
          )
        )

      VStack(alignment: .leading, spacing: 8) {
        if !self.topChips.isEmpty {
          HStack(alignment: .center, spacing: Chip.RECOMMENDED_SPACING) {
            ForEach(self.topChips, id: \.self) { topChip in
              Chip.filled(label: topChip)
            }
          }
          .padding(.top)
          .padding(.horizontal)
        }

        Spacer()

        if !self.bottomChips.isEmpty {
          HStack(alignment: .center, spacing: Chip.RECOMMENDED_SPACING) {
            ForEach(self.bottomChips, id: \.self) { bottomChip in
              Chip.filled(label: bottomChip)
            }
          }
          .padding(.horizontal)
        }

        Text(self.title)
          .frame(maxWidth: .infinity, alignment: .topLeading)
          .foregroundStyle(.white)
          .font(.caption)
          .lineLimit(2)
          .padding(.horizontal, 18)
          .padding(.bottom)
          .id(self.title)
          .transition(.push(from: self.isFocused ? .bottom : .top))
      }
    }
    .background {
      AsyncImage(
        url: self.cover,
        transaction: .init(animation: .easeInOut(duration: IMAGE_FADE_IN_DURATION))
      ) { phase in
        switch phase {
        case .empty:
          ImagePlaceholder.color

        case let .success(image):
          if let uiImage = ImageRenderer(content: image).uiImage, uiImage.size.width >= uiImage.size.height {
            image
              .resizable()
              .scaledToFit()
          }
          else {
            image
              .resizable()
              .scaledToFill()
          }

        case .failure:
          Group {
            ImagePlaceholder.color
              .overlay {
                Image(systemName: "photo")
                  .font(.title)
                  .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
              }
          }

        @unknown default:
          ImagePlaceholder.color
        }
      }
    }
    .aspectRatio(Self.RECOMMENDED_ASPECT_RATIO, contentMode: .fit)
    .clipped()
    .hoverEffect(.highlight)
    .onChange(of: self.isFocused) { _, newValue in
      withAnimation(.spring(duration: 0.5)) {
        if newValue {
          if let secondaryTitle = self.secondaryTitle {
            self.title = secondaryTitle
          }
        }
        else {
          self.title = self.primaryTitle
        }
      }
    }
  }

  static func placeholder() -> some View {
    Self.init(
      topChips: [],
      bottomChips: [],
      cover: nil,
      primaryTitle: String(repeating: " ", count: 15),
      secondaryTitle: nil
    )
    .redacted(reason: .placeholder)
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
      LazyVGrid(
        columns: Array(
          repeating: GridItem(.flexible(), spacing: ShowCard.RECOMMENDED_SPACING),
          count: ShowCard.RECOMMENDED_COUNT_PER_ROW
        ),
        spacing: ShowCard.RECOMMENDED_SPACING
      ) {
        ForEach(0..<100) { index in
          ShowCard(
            topChips: ["9.32", "Лето 2025"],
            bottomChips: ["Фильм"],
            cover: image(index + 1),
            primaryTitle: "Primary Title Primary Title Primary Title",
            secondaryTitle: "Secondary Title"
          )
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
        LazyHStack(alignment: .top, spacing: ShowCard.RECOMMENDED_SPACING) {
          ForEach(0..<100) { index in
            ShowCard(
              topChips: ["9.32", "Лето 2025"],
              bottomChips: ["Фильм"],
              cover: image(index + 1),
              primaryTitle: "Primary Title",
              secondaryTitle: "Secondary Title"
            )
            .containerRelativeFrame(
              .horizontal,
              count: ShowCard.RECOMMENDED_COUNT_PER_ROW,
              span: 1,
              spacing: ShowCard.RECOMMENDED_SPACING
            )
          }
        }
        .scrollClipDisabled()
      }
    }
    .background(Color.gray.ignoresSafeArea())
  }
}
