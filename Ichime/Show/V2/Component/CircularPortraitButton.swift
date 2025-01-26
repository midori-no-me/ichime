import Foundation
import SwiftUI

/// Кнопка с круглой картиной и текстом под ней
///
/// Подходит для портретов людей или персонажей.
struct CircularPortraitButton<Label>: View where Label: View {
  private let imageUrl: URL?
  private let action: () -> Void
  private let label: () -> Label

  @preconcurrency public init(
    imageUrl: URL?,
    action: @escaping @MainActor () -> Void,
    @ViewBuilder label: @escaping () -> Label
  ) {
    self.imageUrl = imageUrl
    self.action = action
    self.label = label
  }

  var body: some View {
    Button(action: self.action) {
      Circle()
        .foregroundColor(Color.gray)
        .overlay(
          AsyncImage(
            url: self.imageUrl,
            transaction: .init(animation: .easeInOut(duration: 0.5))
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
          },
          alignment: .top
        )
        .hoverEffect(.highlight)

      self.label()
    }
    .buttonStyle(.borderless)
    .buttonBorderShape(.circle)
  }
}

#Preview("Grid") {
  let verticalImage = URL(string: "https://cdn.myanimelist.net/images/characters/7/525105.jpg")!
  let horizontalImage = URL(
    string: "https://cdn.myanimelist.net/s/common/uploaded_files/1734408527-daf48cfe8b3e252e7191d1cb9f139e94.png"
  )!

  NavigationStack {
    ScrollView(.vertical) {
      LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 64), count: 6), spacing: 64) {
        ForEach(0..<100) { index in
          CircularPortraitButton(
            imageUrl: index % 2 == 0
              ? verticalImage
              : horizontalImage,
            action: {},
            label: {
              Text(
                index % 2 == 0
                  ? "Portrait \(index + 1)"
                  : "Portrait \(index + 1) with very very long label"
              ).lineLimit(1)
            }
          )
        }
      }
    }
    .background(Color.gray.ignoresSafeArea())
  }
}

#Preview("Horizontal Row") {
  let verticalImage = URL(string: "https://cdn.myanimelist.net/images/characters/7/525105.jpg")!
  let horizontalImage = URL(
    string: "https://cdn.myanimelist.net/s/common/uploaded_files/1734408527-daf48cfe8b3e252e7191d1cb9f139e94.png"
  )!

  NavigationStack {
    ScrollView(.vertical) {
      ScrollView(.horizontal) {
        LazyHStack(alignment: .top, spacing: 64) {
          ForEach(0..<100) { index in
            CircularPortraitButton(
              imageUrl: index % 2 == 0
                ? verticalImage
                : horizontalImage,
              action: {},
              label: {
                Text(
                  index % 2 == 0
                    ? "Portrait \(index + 1)"
                    : "Portrait \(index + 1) with very very long label"
                ).lineLimit(1)
              }
            )
            .containerRelativeFrame(.horizontal, count: 6, span: 1, spacing: 64)
          }
        }
        .scrollClipDisabled()
      }
    }
    .background(Color.gray.ignoresSafeArea())
  }
}
