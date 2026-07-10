import Foundation
import IchimeAnime365
import OrderedCollections

public struct CurrentlyWatchingService: Sendable {
  // MARK: Properties

  private let anime365KitFactory: Anime365KitFactory

  // MARK: Lifecycle

  public init(
    anime365KitFactory: Anime365KitFactory
  ) {
    self.anime365KitFactory = anime365KitFactory
  }

  // MARK: Functions

  public func getEpisodesToWatch(page: Int) async throws -> OrderedSet<EpisodeFromCurrentlyWatchingList> {
    let episodes = try await self.anime365KitFactory
      .createWebClient()
      .getPersonalEpisodes(page: page)

    return .init(
      episodes.map {
        .init(fromAnime365KitNewEpisode: $0)
      }
    )
  }
}
