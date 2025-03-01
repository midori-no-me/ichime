import Foundation
import ScraperAPI

struct MomentService {
  private let scraperApi: ScraperAPI.APIClient

  init(
    scraperApi: ScraperAPI.APIClient
  ) {
    self.scraperApi = scraperApi
  }

  func getMoments(page: Int) async throws -> [Moment] {
    let anime365Moments = try await self.scraperApi.sendAPIRequest(
      ScraperAPI.Request.GetMoments(page: page)
    )

    return anime365Moments.map { .create(anime365Moment: $0) }
  }

  func getShowMoments(showId: Int, page: Int) async throws -> [Moment] {
    let anime365Moments = try await self.scraperApi.sendAPIRequest(
      ScraperAPI.Request.GetMomentsByShow(showId: showId, page: page)
    )

    return anime365Moments.map { .create(anime365Moment: $0) }
  }
}
