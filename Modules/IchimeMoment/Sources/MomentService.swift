import Foundation
import IchimeAnime365
import OrderedCollections

public struct MomentService: Sendable {
  // MARK: Properties

  private let anime365KitFactory: Anime365KitFactory

  // MARK: Lifecycle

  public init(
    anime365KitFactory: Anime365KitFactory
  ) {
    self.anime365KitFactory = anime365KitFactory
  }

  // MARK: Functions

  public func getMomentVideoURL(momentID: Int) async throws -> URL {
    let momentEmbed = try await self.anime365KitFactory.createWebClient().getMomentEmbed(momentID: momentID)

    return momentEmbed.videoURL
  }

  public func getMomentDetails(momentID: Int) async throws -> MomentDetails {
    let momentDetails = try await self.anime365KitFactory.createWebClient().getMomentDetails(momentID: momentID)

    return .init(fromAnime365MomentDetails: momentDetails)
  }

  public func getMoments(page: Int, sorting: MomentSorting) async throws -> OrderedSet<Moment> {
    let anime365Moments = try await self.anime365KitFactory.createWebClient().getMoments(
      page: page,
      sort: sorting.anime365
    )

    return .init(anime365Moments.map { .init(fromAnime365Moment: $0) })
  }

  public func getShowMoments(showID: Int, page: Int) async throws -> OrderedSet<Moment> {
    let anime365Moments = try await self.anime365KitFactory.createWebClient().getMomentsBySeries(
      seriesID: showID,
      page: page,
    )

    return .init(anime365Moments.map { .init(fromAnime365Moment: $0) })
  }
}
