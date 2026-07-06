import Foundation

public struct GetPreviewsResponse: Sendable, Decodable {
  public let animes: [AnimeFieldsForPreview]
}

extension GraphQLClient {
  public func getPreviews(
    page: Int? = nil,
    limit: Int? = nil,
    order: String? = nil,
    season: String? = nil,
    censored: Bool? = nil,
    rating: String? = nil,
    status: String? = nil,
    search: String? = nil,
  ) async throws -> GetPreviewsResponse {
    let query = """
      query GetPreviews($page: PositiveInt, $limit: PositiveInt, $order: OrderEnum, $season: SeasonString, $censored: Boolean, $rating: RatingString, $status: AnimeStatusString, $search: String) {
        animes(page: $page, limit: $limit, order: $order, season: $season, censored: $censored, rating: $rating, status: $status, search: $search) {
          malId
          name
          russian
          kind
          score
          airedOn { month, year }
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
    if let status = status { variables["status"] = AnyEncodable(status) }
    if let search = search { variables["search"] = AnyEncodable(search) }

    return try await sendRequest(
      operationName: "GetPreviews",
      variables: variables,
      query: query,
    )
  }
}
