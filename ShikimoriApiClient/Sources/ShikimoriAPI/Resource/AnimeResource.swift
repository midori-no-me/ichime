extension ShikimoriApiClient {
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
  ) async throws -> [AnimeV1.Screenshot] {
    try await sendRequest(
      httpMethod: .GET,
      endpoint: "/api/animes/\(animeId)/screenshots",
      queryItems: [],
      requestBody: nil
    )
  }
}
