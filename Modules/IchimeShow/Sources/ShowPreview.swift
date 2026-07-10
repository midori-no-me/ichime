import Anime365Kit
import Foundation

public struct ShowPreview: Hashable, Identifiable {
  // MARK: Properties

  public let id: Int
  public let title: ShowName
  public let posterURL: URL?
  public let score: Float?
  public let airingSeason: AiringSeason?
  public let kind: ShowKind?
  public let year: Int?

  // MARK: Lifecycle

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

    self.posterURL = anime365Series.posterUrl

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

  // MARK: Static Functions

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  // MARK: Functions

  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
  }
}
