extension ApiClient {
  public func getAnimeById(
    animeId: Int
  ) async throws -> AnimeV1 {
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
