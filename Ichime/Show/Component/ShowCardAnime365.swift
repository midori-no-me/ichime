import SwiftUI

struct ShowCardAnime365: View {
  private let show: ShowPreview
  private let displaySeason: Bool
  private let hiddenKindChips: Set<ShowKind>
  private let onOpened: (() -> Void)?

  init(
    show: ShowPreview,
    displaySeason: Bool,
    hiddenKindChips: Set<ShowKind> = .init(),
    onOpened: (() -> Void)? = nil
  ) {
    self.show = show
    self.displaySeason = displaySeason
    self.hiddenKindChips = hiddenKindChips
    self.onOpened = onOpened
  }

  var body: some View {
    NavigationLink(
      destination: ShowView(showId: self.show.id, onOpened: self.onOpened)
    ) {
      ShowCard(
        topChips: self.formatTopChips(),
        bottomChips: self.formatBottomChips(),
        cover: self.show.posterUrl,
        primaryTitle: self.show.title.getRomajiOrFullName(),
        secondaryTitle: self.show.title.getRussian()
      )
    }
    #if os(tvOS)
    .buttonStyle(.borderless)
    #else
    .clipShape(.rect(cornerRadius: 16, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(.secondary.opacity(0.5), lineWidth: 1)
        )
    #endif
    .contextMenu {
      NavigationLink(destination: ShowView(showId: self.show.id, onOpened: self.onOpened)) {
        Label(self.show.title.getRomajiOrFullName(), systemImage: "info.circle")

        if let russian = self.show.title.getRussian() {
          Text(russian)
        }
      }
    }
  }

  private func formatTopChips() -> [String] {
    var metadataLineComponents: [String] = []

    if let score = show.score {
      metadataLineComponents.append("★ \(score.formatted(.number.precision(.fractionLength(2))))")
    }

    if let airingSeason = show.airingSeason, displaySeason {
      metadataLineComponents.append(airingSeason.getLocalizedTranslation())
    }

    return metadataLineComponents
  }

  private func formatBottomChips() -> [String] {
    var metadataLineComponents: [String] = []

    if let kind = show.kind, !self.hiddenKindChips.contains(kind) {
      metadataLineComponents.append(kind.title)
    }

    return metadataLineComponents
  }
}
