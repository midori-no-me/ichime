import Foundation

extension ApiClient {
  public func getEpisode(
    episodeId: Int
  ) async throws(ApiClientError) -> EpisodeFull {
    try await sendRequest(
      endpoint: "/episodes/\(episodeId)",
      queryItems: []
    )
  }
}
