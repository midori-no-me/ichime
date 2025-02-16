import SwiftUI

struct HeadingSectionWithBackground<Content: View>: View {
  let imageUrl: URL?

  @ViewBuilder let content: Content

  var body: some View {
    VStack {
      self.content
    }
    .frame(maxWidth: .infinity)
    .background(alignment: .center) {
      GeometryReader { geometry in
        let contentWidth = geometry.size.width
        let contentHeight = geometry.size.height

        let distanceToScreenTop = geometry.frame(in: .global).minY
        let scrollDistance = geometry.frame(in: .scrollView).minY
        let navigationBarHeight = distanceToScreenTop - scrollDistance

        let imageOffset = -distanceToScreenTop + min(0, scrollDistance)
        let backgroundImageHeight = contentHeight + max(distanceToScreenTop, navigationBarHeight)

        AsyncImage(
          url: self.imageUrl,
          transaction: .init(animation: .easeInOut(duration: IMAGE_FADE_IN_DURATION)),
          content: { phase in
            switch phase {
            case .empty:
              Color.clear
            case let .success(image):
              image
                .resizable()
                .scaledToFill()

            case .failure:
              Color.clear
            @unknown default:
              Color.clear
            }
          }
        )
        .frame(
          width: contentWidth,
          height: backgroundImageHeight,
          alignment: .center
        )
        .opacity(0.25)
        #if os(tvOS)
          // На tvOS материалы исчезают при открытии sheet или нажатии на NavigationLink, из-за этого при транзишене исчезает блюр и становится видна заблюренная фоновая картинка. Поэтому используем блюр, а не материалы.
          .blur(radius: 100)
        #else
          .overlay(.thickMaterial)
        #endif
        .clipped()
        .offset(y: imageOffset)
      }
      .ignoresSafeArea()
    }
  }
}

#Preview {
  NavigationStack {
    ScrollView {
      HeadingSectionWithBackground(
        imageUrl: URL(string: "https://anime365.ru/posters/35064.21633814144.jpg")!
      ) {
        Text("Test")
        Text("Test")
        Text("Test")
        Text("Test")
      }

      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
      Text("Text below")
    }

    .navigationTitle("Sousou no Frieren")
  }
}
