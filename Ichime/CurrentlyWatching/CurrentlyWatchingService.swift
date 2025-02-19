import Foundation
import ScraperAPI

struct CurrentlyWatchingService {
  private let scraperApi: ScraperAPI.APIClient

  init(
    scraperApi: ScraperAPI.APIClient
  ) {
    self.scraperApi = scraperApi
  }

  func getEpisodesToWatch(page: Int) async throws -> [EpisodeFromCurrentlyWatchingList] {
    let scraperApiWatchShows = try await self.scraperApi.sendAPIRequest(
      ScraperAPI.Request.GetNextToWatch(page: page)
    )

    return scraperApiWatchShows.map { .init(fromScraperWatchShow: $0) }
  }
}
