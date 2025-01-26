extension ApiClient {
  public func getAnimeCharacters(
    id: Int
  ) async throws -> [CharacterRole] {
    try await sendRequest(
      endpoint: "/anime/\(id)/characters",
      queryItems: []
    )
  }
}
