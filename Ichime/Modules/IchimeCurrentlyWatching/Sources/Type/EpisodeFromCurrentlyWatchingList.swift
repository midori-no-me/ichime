import Anime365Kit
import Foundation
import IchimeShow

public struct EpisodeFromCurrentlyWatchingList: Hashable, Identifiable {
  public let showName: ShowName
  public let episodeTitle: String
  public let showId: Int
  public let episodeId: Int
  public let coverUrl: URL?

  public var id: Int {
    self.episodeId
  }

  public init(fromAnime365KitNewEpisode: Anime365Kit.NewPersonalEpisode) {
    self.showName = .parsed(
      fromAnime365KitNewEpisode.seriesTitleRomaji,
      fromAnime365KitNewEpisode.seriesTitleRu
    )

    self.episodeTitle = fromAnime365KitNewEpisode.episodeNumberLabel
    self.showId = fromAnime365KitNewEpisode.seriesId
    self.episodeId = fromAnime365KitNewEpisode.episodeId
    self.coverUrl = fromAnime365KitNewEpisode.seriesPosterURL
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.episodeId == rhs.episodeId
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.episodeId)
  }
}
