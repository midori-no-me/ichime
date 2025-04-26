import Foundation
import OrderedCollections
import ScraperAPI

struct MomentService {
  private let scraperApi: ScraperAPI.APIClient

  init(
    scraperApi: ScraperAPI.APIClient
  ) {
    self.scraperApi = scraperApi
  }

  private static func momentSortingToScraperSorting(_ sorting: MomentSorting)
    -> ScraperAPI.Request.GetMoments.MomentSorting
  {
    switch sorting {
    case .newest:
      .newest
    case .popular:
      .popular
    }
  }

  func getMoments(page: Int, sorting: MomentSorting) async throws -> OrderedSet<Moment> {
    let anime365Moments = try await self.scraperApi.sendAPIRequest(
      ScraperAPI.Request.GetMoments(
        page: page,
        filter: .init(sort: Self.momentSortingToScraperSorting(sorting))
      )
    )

    return .init(anime365Moments.map { .create(anime365Moment: $0) })
  }

  func getShowMoments(showId: Int, page: Int) async throws -> OrderedSet<Moment> {
    let anime365Moments = try await self.scraperApi.sendAPIRequest(
      ScraperAPI.Request.GetMomentsByShow(showId: showId, page: page)
    )

    return .init(anime365Moments.map { .create(anime365Moment: $0) })
  }
}
