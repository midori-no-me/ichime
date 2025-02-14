import SwiftUI

struct RelatedShowCard: View {
  let relatedShow: RelatedShow

  var body: some View {
    NavigationLink(
      destination: ShowByMyAnimeListIdView(myAnimeListId: self.relatedShow.myAnimeListId)
    ) {
      RawShowCard(
        metadataLineComponents: self.formatMetadataLine(),
        cover: self.relatedShow.posterUrl,
        primaryTitle: self.relatedShow.title.japaneseRomaji,
        secondaryTitle: self.relatedShow.title.russian
      )
    }
    .buttonStyle(.borderless)
  }

  private func formatMetadataLine() -> [String] {
    var metadataLineComponents: [String] = []

    if let score = relatedShow.score {
      metadataLineComponents.append("★ \(score.formatted(.number.precision(.fractionLength(2))))")
    }

    if let airingSeason = relatedShow.airingSeason {
      metadataLineComponents.append(airingSeason.getLocalizedTranslation())
    }

    return metadataLineComponents
  }
}
