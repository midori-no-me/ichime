import SwiftUI

struct ShowCardShikimori: View {
  let show: ShowPreviewShikimori
  let displaySeason: Bool

  var body: some View {
    NavigationLink(
      destination: ShowByMyAnimeListIdView(myAnimeListId: self.show.id)
    ) {
      RawShowCard(
        metadataLineComponents: self.formatMetadataLine(),
        cover: self.show.posterUrl,
        primaryTitle: self.show.title.getRomajiOrFullName(),
        secondaryTitle: self.show.title.getRussian()
      )
    }
    .buttonStyle(.borderless)
  }

  private func formatMetadataLine() -> [String] {
    var metadataLineComponents: [String] = []

    if let score = show.score {
      metadataLineComponents.append("★ \(score.formatted(.number.precision(.fractionLength(2))))")
    }

    if let airingSeason = show.airingSeason, displaySeason {
      metadataLineComponents.append(airingSeason.getLocalizedTranslation())
    }

    if let kind = show.kind, kind != .tv {
      metadataLineComponents.append(kind.title)
    }

    return metadataLineComponents
  }
}
