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

    let variables: [String: AnyEncodable] = [
      "page": AnyEncodable(page),
      "limit": AnyEncodable(limit),
      "order": AnyEncodable(order),
      "season": AnyEncodable(season),
      "censored": AnyEncodable(censored),
      "rating": AnyEncodable(rating),
    ].compactMapValues { $0 }

    return try await sendRequest(
      operationName: "GetPreviews",
      variables: variables,
      query: query,
    )
  }
}
