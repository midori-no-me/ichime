import Foundation

extension ApiClient {
  public func getEpisode(
    episodeId: Int
  ) async throws -> EpisodeFull {
    try await sendRequest(
      endpoint: "/episodes/\(episodeId)",
      queryItems: []
    )
  }
}
