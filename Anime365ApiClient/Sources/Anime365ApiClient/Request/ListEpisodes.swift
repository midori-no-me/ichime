import Foundation

extension ApiClient {
  public func listEpisodes(
    seriesId: Int? = nil,
    limit: Int? = nil,
    offset: Int? = nil
  ) async throws -> [Episode] {
    var queryItems: [URLQueryItem] = []

    if let seriesId {
      queryItems.append(
        URLQueryItem(
          name: "seriesId",
          value: String(seriesId)
        )
      )
    }

    if let limit {
      queryItems.append(
        URLQueryItem(
          name: "limit",
          value: String(limit)
        )
      )
    }

    if let offset {
      queryItems.append(
        URLQueryItem(
          name: "offset",
          value: String(offset)
        )
      )
    }

    return try await sendRequest(
      endpoint: "/episodes",
      queryItems: queryItems
    )
  }
}
