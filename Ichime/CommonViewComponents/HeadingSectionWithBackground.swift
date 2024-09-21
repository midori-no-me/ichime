import SwiftUI

struct HeadingSectionWithBackground<Content: View>: View {
    public let imageUrl: URL?

    @ViewBuilder let content: Content

    var body: some View {
        VStack {
            content
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

                Group {
                    if let imageUrl {
                        AsyncImage(
                            url: imageUrl,
                            transaction: .init(animation: .easeInOut(duration: 0.8)),
                            content: { phase in
                                switch phase {
                                case .empty:
                                    EmptyView()
                                case let .success(image):
                                    image
                                        .resizable()
                                        .scaledToFill()

                                case .failure:
                                    EmptyView()
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        )
                    } else {
                        Color.clear
                    }
                }
                .frame(
                    width: contentWidth,
                    height: backgroundImageHeight,
                    alignment: .center
                )
                .overlay(.thickMaterial)
                .clipped()
                .offset(y: imageOffset)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            HeadingSectionWithBackground(imageUrl: URL(string: "https://anime365.ru/posters/35064.21633814144.jpg")!) {
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
