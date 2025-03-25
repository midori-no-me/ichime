import SwiftUI

struct ShowCard: View {
  private let show: ShowPreview
  private let displaySeason: Bool
  private let onOpened: (() -> Void)?

  init(
    show: ShowPreview,
    displaySeason: Bool,
    onOpened: (() -> Void)? = nil
  ) {
    self.show = show
    self.displaySeason = displaySeason
    self.onOpened = onOpened
  }

  var body: some View {
    NavigationLink(
      destination: ShowView(showId: self.show.id, onOpened: self.onOpened)
    ) {
      RawShowCard(
        metadataLineComponents: self.formatMetadataLine(),
        cover: self.show.posterUrl,
        primaryTitle: self.romajiTitle(),
        secondaryTitle: self.russianTitle()
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

  private func romajiTitle() -> String {
    if let parsedShowName = self.show.title as? ParsedShowName {
      return parsedShowName.romaji
    }

    return self.show.title.getFullName()
  }

  private func russianTitle() -> String? {
    if let parsedShowName = self.show.title as? ParsedShowName {
      return parsedShowName.russian
    }

    return nil
  }
}
