import Anime365Kit
import Foundation

struct AnimeListEntry: Identifiable, Hashable {
  let id: Int
  let name: ShowName
  let episodesWatched: Int
  let episodesTotal: Int?

  init(
    fromAnime365KitAnimeListEntry: Anime365Kit.AnimeListEntry
  ) {
    self.id = fromAnime365KitAnimeListEntry.seriesId
    self.name = .fromFullName(fromAnime365KitAnimeListEntry.seriesTitleFull)
    self.episodesWatched = fromAnime365KitAnimeListEntry.episodesWatched
    self.episodesTotal = fromAnime365KitAnimeListEntry.episodesTotal
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
  }
}
