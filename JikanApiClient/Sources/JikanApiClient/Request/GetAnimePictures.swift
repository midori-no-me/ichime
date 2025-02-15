extension ApiClient {
  public func getAnimePictures(
    id: Int
  ) async throws -> [ImageInDifferentFormats] {
    try await sendRequest(
      endpoint: "/anime/\(id)/pictures",
      queryItems: []
    )
  }
}
