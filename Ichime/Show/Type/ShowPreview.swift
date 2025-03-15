import Anime365ApiClient
import Foundation

struct ShowPreview: Hashable, Identifiable {
  let id: Int
  let title: ShowName
  let posterUrl: URL?
  let score: Float?
  let airingSeason: AiringSeason?
  let kind: ShowKind?

  init(
    anime365Series: Anime365ApiClient.Series
  ) {
    self.id = anime365Series.id

    if let romajiTitle = anime365Series.titles.romaji {
      self.title = ParsedShowName(russian: anime365Series.titles.ru, romaji: romajiTitle)
    }
    else {
      self.title = UnparsedShowName(fullName: anime365Series.title)
    }

    self.posterUrl = anime365Series.posterUrl

    if let score = Float(anime365Series.myAnimeListScore), score > 0 {
      self.score = score
    }
    else {
      self.score = nil
    }

    self.airingSeason = .init(fromTranslatedString: anime365Series.season)

    if let seriesType = anime365Series.type {
      self.kind = .create(seriesType)
    }
    else {
      self.kind = nil
    }
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
  }
}
