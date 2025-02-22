import Foundation
import SwiftUI

struct SeasonCard: View {
  let season: AiringSeason
  let showCovers: [URL]

  var body: some View {
    NavigationLink(destination: Text("Test")) {
      VStack(alignment: .leading, spacing: 0) {
        Text(self.season.getLocalizedTranslation())
          .frame(maxWidth: .infinity, alignment: .leading)
          .font(.title2)
          .padding(32)

        Spacer(minLength: 0)

        HStack(alignment: .center, spacing: 32) {
          ForEach(Array(self.showCovers.enumerated()), id: \.element) { index, showCover in
            AsyncImage(
              url: showCover,
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
                Color.clear

              @unknown default:
                Color.clear
              }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(
              maxWidth: .infinity,
              maxHeight: .infinity,
              alignment: .top
            )
            .aspectRatio(425 / 600, contentMode: .fit)
            .offset(y: CGFloat(-20 + (index * 20)))
          }
        }
        .padding(.horizontal, 32)
        .frame(
          maxWidth: .infinity,
          maxHeight: .infinity,
          alignment: .center
        )
        .aspectRatio(1.5 / 1, contentMode: .fit)
        .background {
          AsyncImage(
            url: self.showCovers.first,
            transaction: .init(animation: .easeInOut(duration: IMAGE_FADE_IN_DURATION))
          ) { phase in
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
          #if os(tvOS)
            // На tvOS материалы исчезают при открытии sheet или нажатии на NavigationLink, из-за этого при транзишене исчезает блюр и становится видна заблюренная фоновая картинка. Поэтому используем блюр, а не материалы.
            .opacity(0.5)
            .blur(radius: 100)
          #else
            .overlay(.thickMaterial)
          #endif
        }
        .clipped()
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .buttonStyle(.card)
  }
}

#Preview("Horizontal Row") {
  NavigationStack {
    ScrollView(.vertical) {
      ScrollView(.horizontal) {
        LazyHStack(alignment: .top, spacing: 64) {
          ForEach(0..<15) { index in
            SeasonCard(
              season: .init(calendarSeason: .autumn, year: 2025),
              showCovers: [
                URL(
                  string:
                    "https://cdn.myanimelist.net/s/common/uploaded_files/1734408527-daf48cfe8b3e252e7191d1cb9f139e94.png"
                )!,
                URL(
                  string:
                    "https://cdn.myanimelist.net/r/84x124/images/characters/16/371204.jpg?s=527c14ef55a9df04ba10c32936d573d0"
                )!,
                URL(string: "https://cdn.myanimelist.net/images/characters/7/525105.jpg")!,
              ]
            )
            .containerRelativeFrame(.horizontal, count: 2, span: 1, spacing: 64)
          }
        }
        .scrollClipDisabled()
      }
    }
    .background(Color.gray.ignoresSafeArea())
  }
}
