import Foundation

extension ApiClient {
  public func listSeries(
    query: String? = nil,
    limit: Int? = nil,
    offset: Int? = nil,
    chips: [String: String]? = nil,
    myAnimeListId: Int? = nil
  ) async throws(ApiClientError) -> [Series] {
    var queryItems: [URLQueryItem] = []

    if let chips {
      queryItems.append(
        URLQueryItem(
          name: "chips",
          value:
            chips
            .sorted { $0.key < $1.key }
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: ";")
        )
      )
    }

    if let query {
      queryItems.append(
        URLQueryItem(
          name: "query",
          value: query
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

    if let myAnimeListId {
      queryItems.append(
        URLQueryItem(
          name: "myAnimeListId",
          value: String(myAnimeListId)
        )
      )
    }

    return try await sendRequest(
      endpoint: "/series",
      queryItems: queryItems
    )
  }
}
