import IchimeCalendar
import IchimeEpisode
import IchimeShow
import SwiftUI

struct ShowCardMyAnimeList: View {
  // MARK: Properties

  private let myAnimeListID: Int
  private let topChips: [String]
  private let bottomChips: [String]
  private let cover: URL?
  private let primaryTitle: String
  private let secondaryTitle: String?
  private let onOpened: (() -> Void)?

  // MARK: Lifecycle

  init(
    show: ShowPreviewShikimori,
    displaySeason: Bool,
    hiddenKindChips: Set<ShowKind> = .init(),
    onOpened: (() -> Void)? = nil
  ) {
    self.onOpened = onOpened
    self.myAnimeListID = show.id

    var topChips: [String] = []

    if let score = show.score {
      topChips.append("★ \(score.formatted(.number.precision(.fractionLength(2))))")
    }

    if displaySeason {
      if let airingSeason = show.airingSeason {
        topChips.append(airingSeason.getLocalizedTranslation())
      }
      else if let year = show.year {
        topChips.append("\(year) г.")
      }
    }

    self.topChips = topChips

    var bottomChips: [String] = []

    if let kind = show.kind, !hiddenKindChips.contains(kind) {
      bottomChips.append(kind.title)
    }

    self.bottomChips = bottomChips
    self.cover = show.posterURL
    self.primaryTitle = show.title.getRomajiOrFullName()
    self.secondaryTitle = show.title.getRussian()
  }

  init(
    show: ShowFromCalendarWithExactReleaseDate
  ) {
    self.myAnimeListID = show.id

    var topChips: [String] = []

    if let nextEpisodeNumber = show.nextEpisodeNumber {
      topChips.append("\(nextEpisodeNumber.formatted(EpisodeNumberFormatter())) серия")
    }

    self.topChips = topChips
    self.bottomChips = []
    self.cover = show.posterURL
    self.primaryTitle = show.title.getRomajiOrFullName()
    self.secondaryTitle = show.title.getRussian()
    self.onOpened = nil
  }

  // MARK: Content Properties

  var body: some View {
    NavigationLink(
      destination: ShowByMyAnimeListIDView(myAnimeListID: self.myAnimeListID, onOpened: self.onOpened)
    ) {
      ShowCard(
        topChips: self.topChips,
        bottomChips: self.bottomChips,
        cover: self.cover,
        primaryTitle: self.primaryTitle,
        secondaryTitle: self.secondaryTitle
      )
    }
    .buttonStyle(.borderless)
    .contextMenu {
      NavigationLink(destination: ShowByMyAnimeListIDView(myAnimeListID: self.myAnimeListID, onOpened: nil)) {
        Label(self.primaryTitle, systemImage: "info.circle")

        if let russian = self.secondaryTitle {
          Text(russian)
        }
      }
    }
  }
}
