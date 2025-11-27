import Foundation

extension ApiClient {
  public func listGenres() async throws -> [Genre] {
    try await sendRequest(
      httpMethod: .GET,
      endpoint: "/api/genres",
      queryItems: [],
      requestBody: nil
    )
  }
}
