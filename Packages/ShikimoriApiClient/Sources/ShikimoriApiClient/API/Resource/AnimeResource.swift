import Foundation

extension ApiClient {
  public func getAnimeByID(
    animeID: Int
  ) async throws -> Anime {
    try await sendRequest(
      httpMethod: .GET,
      endpoint: "/api/animes/\(animeID)",
      queryItems: [],
      requestBody: nil
    )
  }
}
