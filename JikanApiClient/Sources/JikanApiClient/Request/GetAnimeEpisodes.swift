import Foundation

extension ApiClient {
  public func getAnimeEpisodes(
    id: Int,
    page: Int? = nil
  ) async throws -> [Episode] {
    var queryItems: [URLQueryItem] = []

    if let page {
      queryItems.append(
        URLQueryItem(
          name: "page",
          value: String(page)
        )
      )
    }

    return try await sendRequest(
      endpoint: "/anime/\(id)/episodes",
      queryItems: queryItems
    )
  }
}
