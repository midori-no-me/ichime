import Foundation

extension ApiClient {
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
