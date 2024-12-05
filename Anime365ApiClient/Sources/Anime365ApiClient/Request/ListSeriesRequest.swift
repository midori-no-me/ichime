import Foundation

public struct ListSeriesRequest: Anime365ApiRequest {
  public typealias ResponseType = [Anime365ApiSeries]

  private let query: String?
  private let limit: Int?
  private let offset: Int?
  private let chips: [String: String]?

  public init(
    query: String? = nil,
    limit: Int? = nil,
    offset: Int? = nil,
    chips: [String: String]? = nil
  ) {
    self.query = query
    self.limit = limit
    self.offset = offset
    self.chips = chips
  }

  public func getEndpoint() -> String {
    "/series"
  }

  public func getQueryItems() -> [URLQueryItem] {
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

    return queryItems
  }
}
