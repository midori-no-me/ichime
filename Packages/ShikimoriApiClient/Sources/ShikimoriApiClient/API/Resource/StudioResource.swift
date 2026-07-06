import Foundation

extension ApiClient {
  public func listStudios() async throws -> [Studio] {
    try await sendRequest(
      httpMethod: .GET,
      endpoint: "/api/studios",
      queryItems: [],
      requestBody: nil
    )
  }
}
