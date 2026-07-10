import Anime365Kit
import Foundation

public struct AnimeListEditableEntry {
  // MARK: Properties

  public let episodesWatched: Int
  public let score: AnimeListScore
  public let status: AnimeListEntryStatus

  // MARK: Lifecycle

  public init(
    fromAnime365KitAnimeListEditableEntry: Anime365Kit.AnimeListEditableEntry
  ) {
    self.episodesWatched = fromAnime365KitAnimeListEditableEntry.episodesWatched

    if let score = AnimeListScore(rawValue: fromAnime365KitAnimeListEditableEntry.score ?? 0) {
      self.score = score
    }
    else {
      self.score = .none
    }

    self.status = .init(fromAnime365KitType: fromAnime365KitAnimeListEditableEntry.status)
  }
}
