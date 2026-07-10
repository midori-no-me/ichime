extension ApiClient {
  public func getAnimeFullByID(
    id: Int
  ) async throws -> Anime {
    try await sendRequest(
      endpoint: "/anime/\(id)",
      queryItems: []
    )
  }
}
