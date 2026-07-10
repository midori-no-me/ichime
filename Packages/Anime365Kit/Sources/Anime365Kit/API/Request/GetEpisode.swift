import Foundation

extension ApiClient {
  public func getEpisode(
    episodeID: Int
  ) async throws(ApiClientError) -> EpisodeFull {
    try await sendRequest(
      endpoint: "/episodes/\(episodeID)",
      queryItems: []
    )
  }
}
