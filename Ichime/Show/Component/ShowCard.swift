import SwiftUI

struct ShowCard: View {
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
            gradient: Gradient(colors: [Color.clear, Color.clear, Color.black]),
            startPoint: .center,
            endPoint: .bottom
          )
        )

      VStack(alignment: .leading, spacing: 4) {
        if !self.topChips.isEmpty {
          HStack(alignment: .center, spacing: 4) {
            ForEach(self.topChips, id: \.self) { topChip in
              ShowCardChip(label: topChip)
            }
          }
          .padding(.top)
          .padding(.horizontal)
        }

        Spacer()

        if !self.bottomChips.isEmpty {
          HStack(alignment: .center, spacing: 4) {
            ForEach(self.bottomChips, id: \.self) { bottomChip in
              ShowCardChip(label: bottomChip)
            }
          }
          .padding(.horizontal)
          .padding(.bottom, 4)
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
          Color.clear

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
            RoundedRectangle(cornerRadius: 16)
              .foregroundStyle(Color(UIColor.systemGray))
              .overlay {
                Image(systemName: "photo")
                  .font(.title)
                  .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
              }
          }

        @unknown default:
          Color.clear
        }
      }
    }
    .aspectRatio(0.7123, contentMode: .fit)
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

private struct ShowCardChip: View {
  let label: String

  var body: some View {
    Text(self.label)
      .font(.caption2)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(.ultraThickMaterial)
      .clipShape(RoundedRectangle(cornerRadius: 8))
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
