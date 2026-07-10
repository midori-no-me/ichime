import Anime365Kit
import Foundation
import IchimeShow

public struct AnimeListEntry: Identifiable, Hashable {
  public let id: Int
  public let name: ShowName
  public let episodesWatched: Int
  public let episodesTotal: Int?

  public init(
    fromAnime365KitAnimeListEntry: Anime365Kit.AnimeListEntry
  ) {
    self.id = fromAnime365KitAnimeListEntry.seriesID
    self.name = .fromFullName(fromAnime365KitAnimeListEntry.seriesTitleFull)
    self.episodesWatched = fromAnime365KitAnimeListEntry.episodesWatched
    self.episodesTotal = fromAnime365KitAnimeListEntry.episodesTotal
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
  }
}
