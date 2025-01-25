extension ApiClient {
  public func getAnimeEpisodes(
    id: Int
  ) async throws -> [Episode] {
    try await sendRequest(
      endpoint: "/anime/\(id)/episodes",
      queryItems: []
    )
  }
}
