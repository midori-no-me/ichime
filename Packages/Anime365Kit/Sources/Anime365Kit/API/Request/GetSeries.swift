import Foundation

extension ApiClient {
  public func getSeries(
    seriesId: Int
  ) async throws(ApiClientError) -> SeriesFull {
    try await sendRequest(
      endpoint: "/series/\(seriesId)",
      queryItems: []
    )
  }
}
