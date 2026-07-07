import Anime365Kit
import Foundation

public struct ShowPreview: Hashable, Identifiable {
  public let id: Int
  public let title: ShowName
  public let posterUrl: URL?
  public let score: Float?
  public let airingSeason: AiringSeason?
  public let kind: ShowKind?
  public let year: Int?

  public init(
    anime365Series: Anime365Kit.Series
  ) {
    self.id = anime365Series.id

    if let romajiTitle = anime365Series.titles.romaji {
      self.title = .parsed(romajiTitle, anime365Series.titles.ru)
    }
    else {
      self.title = .unparsed(anime365Series.title)
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

    if let year = anime365Series.year, year > 0 {
      self.year = year
    }
    else {
      self.year = nil
    }
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
  }
}
