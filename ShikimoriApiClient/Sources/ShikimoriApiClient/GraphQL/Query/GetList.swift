import Foundation

public struct GetPreviewsResponse: Sendable, Decodable {
  public let animes: [GraphQLAnimePreview]
}

extension GraphQLClient {
  public func getPreviews(
    page: Int? = nil,
    limit: Int? = nil,
    order: String? = nil,
    season: String? = nil,
    censored: Bool? = nil,
    rating: String? = nil
  ) async throws -> GetPreviewsResponse {
    let query = """
      query GetPreviews($page: PositiveInt, $limit: PositiveInt, $order: OrderEnum, $season: SeasonString, $censored: Boolean, $rating: RatingString) {
        animes(page: $page, limit: $limit, order: $order, season: $season, censored: $censored, rating: $rating) {
          malId
          name
          russian
          kind
          score
          season
          poster { previewAlt2xUrl }
        }
      }
      """

    var variables: [String: AnyEncodable] = [:]
    if let page = page { variables["page"] = AnyEncodable(page) }
    if let limit = limit { variables["limit"] = AnyEncodable(limit) }
    if let order = order { variables["order"] = AnyEncodable(order) }
    if let season = season { variables["season"] = AnyEncodable(season) }
    if let censored = censored { variables["censored"] = AnyEncodable(censored) }
    if let rating = rating { variables["rating"] = AnyEncodable(rating) }

    return try await sendRequest(
      operationName: "GetPreviews",
      variables: variables,
      query: query,
    )
  }
}
