import Foundation

extension ApiClient {
  public func getAnimeEpisodeById(
    animeId: Int,
    episodeId: Int
  ) async throws -> Episode {
    try await sendRequest(
      endpoint: "/anime/\(animeId)/episodes/\(episodeId)",
      queryItems: []
    )
  }
}
