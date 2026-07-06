extension ApiClient {
  public func getAnimeFullById(
    id: Int
  ) async throws -> Anime {
    try await sendRequest(
      endpoint: "/anime/\(id)",
      queryItems: []
    )
  }
}
