import Foundation
import SwiftUI

/// Кнопка с круглой картиной и текстом под ней
///
/// Подходит для портретов людей или персонажей.
struct CircularPortraitButton<Label>: View where Label: View {
  private let imageUrl: URL?
  private let action: () -> Void
  private let label: () -> Label

  @preconcurrency init(
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
        .foregroundStyle(.regularMaterial)
        .overlay(
          AsyncImage(
            url: self.imageUrl,
            transaction: .init(animation: .easeInOut(duration: IMAGE_FADE_IN_DURATION))
          ) { phase in
            switch phase {
            case .empty:
              PortraitNotLoadedPlaceholder()

            case let .success(image):
              image
                .resizable()
                .scaledToFill()
            case .failure:
              PortraitNotLoadedPlaceholder()

            @unknown default:
              PortraitNotLoadedPlaceholder()
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

private struct PortraitNotLoadedPlaceholder: View {
  var body: some View {
    Image(systemName: "person.fill")
      .foregroundStyle(.secondary)
      .font(.title)
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
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
      LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 64), count: 6), spacing: 64) {
        ForEach(0..<100) { index in
          CircularPortraitButton(
            imageUrl: image(index + 1),
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
            CircularPortraitButton(
              imageUrl: image(index + 1),
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
