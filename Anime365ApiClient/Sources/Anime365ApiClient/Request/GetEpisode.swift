import Foundation

extension ApiClient {
  public func getEpisode(
    episodeId: Int
  ) async throws -> Episode {
    try await sendRequest(
      endpoint: "/episodes/\(episodeId)",
      queryItems: []
    )
  }
}
