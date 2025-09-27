import Foundation
import OrderedCollections

struct CurrentlyWatchingService: Sendable {
  private let anime365KitFactory: Anime365KitFactory

  init(
    anime365KitFactory: Anime365KitFactory
  ) {
    self.anime365KitFactory = anime365KitFactory
  }

  func getEpisodesToWatch(page: Int) async throws -> OrderedSet<EpisodeFromCurrentlyWatchingList> {
    let episodes = try await self.anime365KitFactory
      .createWebClient()
      .getNewEpisodes(page: page)

    return .init(
      episodes.map {
        .init(fromAnime365KitNewEpisode: $0)
      }
    )
  }
}
