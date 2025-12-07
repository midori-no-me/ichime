import Anime365Kit
import Foundation

struct RecentlyUploadedEpisode: Hashable, Identifiable {
  let showName: ShowName
  let episodeTitle: String
  let showId: Int
  let episodeId: Int
  let coverUrl: URL?

  var id: Int {
    self.episodeId
  }

  init(fromAnime365KitNewEpisode: Anime365Kit.NewRecentEpisode) {
    self.showName = .parsed(
      fromAnime365KitNewEpisode.seriesTitleRomaji,
      fromAnime365KitNewEpisode.seriesTitleRu
    )

    self.episodeTitle = fromAnime365KitNewEpisode.episodeNumberLabel
    self.showId = fromAnime365KitNewEpisode.seriesId
    self.episodeId = fromAnime365KitNewEpisode.episodeId
    self.coverUrl = fromAnime365KitNewEpisode.seriesPosterURL
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.episodeId == rhs.episodeId
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(self.episodeId)
  }
}
