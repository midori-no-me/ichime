import Foundation
import OrderedCollections

struct MomentService {
  private let anime365KitFactory: Anime365KitFactory

  init(
    anime365KitFactory: Anime365KitFactory
  ) {
    self.anime365KitFactory = anime365KitFactory
  }

  func getMomentVideoURL(momentId: Int) async throws -> URL {
    let momentEmbed = try await self.anime365KitFactory.createWebClient().getMomentEmbed(momentID: momentId)

    return momentEmbed.videoURL
  }

  func getMoments(page: Int, sorting: MomentSorting) async throws -> OrderedSet<Moment> {
    let anime365Moments = try await self.anime365KitFactory.createWebClient().getMoments(
      page: page,
      sort: sorting.anime365
    )

    return .init(anime365Moments.map { .init(fromAnime365Moment: $0) })
  }

  func getShowMoments(showId: Int, page: Int) async throws -> OrderedSet<Moment> {
    let anime365Moments = try await self.anime365KitFactory.createWebClient().getMomentsBySeries(
      seriesId: showId,
      page: page,
    )

    return .init(anime365Moments.map { .init(fromAnime365Moment: $0) })
  }
}
