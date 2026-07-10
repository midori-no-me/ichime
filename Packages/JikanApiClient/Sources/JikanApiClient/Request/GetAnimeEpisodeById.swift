import Foundation

extension ApiClient {
  public func getAnimeEpisodeByID(
    animeID: Int,
    episodeID: Int
  ) async throws -> Episode {
    try await sendRequest(
      endpoint: "/anime/\(animeID)/episodes/\(episodeID)",
      queryItems: []
    )
  }
}
