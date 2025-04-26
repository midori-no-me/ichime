import Foundation
import OrderedCollections
import ScraperAPI

struct CurrentlyWatchingService {
  private let scraperApi: ScraperAPI.APIClient

  init(
    scraperApi: ScraperAPI.APIClient
  ) {
    self.scraperApi = scraperApi
  }

  func getEpisodesToWatch(page: Int) async throws -> OrderedSet<EpisodeFromCurrentlyWatchingList> {
    let scraperApiWatchShows = try await self.scraperApi.sendAPIRequest(
      ScraperAPI.Request.GetNextToWatch(page: page)
    )

    return .init(scraperApiWatchShows.map { .init(fromScraperWatchShow: $0) })
  }
}
