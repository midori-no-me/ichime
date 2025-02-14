import SwiftUI

struct WatchCard: View {
  let data: WatchCardModel

  var body: some View {
    NavigationLink(value: self.data) {
      RawShowCard(
        metadataLineComponents: [self.data.title, self.data.sideText],
        cover: self.data.image,
        primaryTitle: self.data.name.romaji,
        secondaryTitle: self.data.name.ru
      )
    }
    .buttonStyle(.borderless)
  }
}
