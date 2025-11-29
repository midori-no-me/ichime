import SwiftUI

struct ShowCardMyAnimeList: View {
  private let myAnimeListId: Int
  private let topChips: [String]
  private let bottomChips: [String]
  private let cover: URL?
  private let primaryTitle: String
  private let secondaryTitle: String?

  init(
    show: ShowPreviewShikimori,
    displaySeason: Bool
  ) {
    self.myAnimeListId = show.id

    var topChips: [String] = []

    if let score = show.score {
      topChips.append("★ \(score.formatted(.number.precision(.fractionLength(2))))")
    }

    if let airingSeason = show.airingSeason, displaySeason {
      topChips.append(airingSeason.getLocalizedTranslation())
    }

    self.topChips = topChips

    var bottomChips: [String] = []

    if let kind = show.kind, kind != .tv {
      bottomChips.append(kind.title)
    }

    self.bottomChips = bottomChips
    self.cover = show.posterUrl
    self.primaryTitle = show.title.getRomajiOrFullName()
    self.secondaryTitle = show.title.getRussian()
  }

  init(
    show: ShowFromCalendarWithExactReleaseDate
  ) {
    self.myAnimeListId = show.id

    var topChips: [String] = []

    if let nextEpisodeNumber = show.nextEpisodeNumber {
      topChips.append("\(nextEpisodeNumber.formatted(EpisodeNumberFormatter())) серия")
    }

    self.topChips = topChips
    self.bottomChips = []
    self.cover = show.posterUrl
    self.primaryTitle = show.title.getRomajiOrFullName()
    self.secondaryTitle = show.title.getRussian()
  }

  var body: some View {
    NavigationLink(
      destination: ShowByMyAnimeListIdView(myAnimeListId: self.myAnimeListId)
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
      NavigationLink(destination: ShowByMyAnimeListIdView(myAnimeListId: self.myAnimeListId)) {
        Label(self.primaryTitle, systemImage: "info.circle")

        if let russian = self.secondaryTitle {
          Text(russian)
        }
      }
    }
  }
}
