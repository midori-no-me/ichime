import Foundation

extension ApiClient {
  public func listAnimes(
    page: Int? = nil,
    limit: Int? = nil,
    order: String? = nil,
    season: String? = nil
  ) async throws -> [AnimePreview] {
    var queryItems: [URLQueryItem] = []

    if let page {
      queryItems.append(
        URLQueryItem(
          name: "page",
          value: String(page)
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

    if let order {
      queryItems.append(
        URLQueryItem(
          name: "order",
          value: order
        )
      )
    }

    if let season {
      queryItems.append(
        URLQueryItem(
          name: "season",
          value: season
        )
      )
    }

    return try await sendRequest(
      httpMethod: .GET,
      endpoint: "/api/animes",
      queryItems: queryItems,
      requestBody: nil
    )
  }

  public func getAnimeById(
    animeId: Int
  ) async throws -> Anime {
    try await sendRequest(
      httpMethod: .GET,
      endpoint: "/api/animes/\(animeId)",
      queryItems: [],
      requestBody: nil
    )
  }

  public func getAnimeScreenshotsById(
    animeId: Int
  ) async throws -> [ImageVariants] {
    try await sendRequest(
      httpMethod: .GET,
      endpoint: "/api/animes/\(animeId)/screenshots",
      queryItems: [],
      requestBody: nil
    )
  }

  public func getAnimeRelatedById(
    animeId: Int
  ) async throws -> [Relation] {
    try await sendRequest(
      httpMethod: .GET,
      endpoint: "/api/animes/\(animeId)/related",
      queryItems: [],
      requestBody: nil
    )
  }
}
