import Anime365Kit
import Foundation
import IchimeShow

public struct RecentlyUploadedEpisode: Hashable, Identifiable {
  // MARK: Properties

  public let showName: ShowName
  public let episodeTitle: String
  public let showID: Int
  public let episodeID: Int
  public let coverURL: URL?

  // MARK: Computed Properties

  public var id: Int {
    self.episodeID
  }

  // MARK: Lifecycle

  public init(fromAnime365KitNewEpisode: Anime365Kit.NewRecentEpisode) {
    self.showName = .parsed(
      fromAnime365KitNewEpisode.seriesTitleRomaji,
      fromAnime365KitNewEpisode.seriesTitleRu
    )

    self.episodeTitle = fromAnime365KitNewEpisode.episodeNumberLabel
    self.showID = fromAnime365KitNewEpisode.seriesID
    self.episodeID = fromAnime365KitNewEpisode.episodeID
    self.coverURL = fromAnime365KitNewEpisode.seriesPosterURL
  }

  // MARK: Static Functions

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.episodeID == rhs.episodeID
  }

  // MARK: Functions

  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.episodeID)
  }
}
