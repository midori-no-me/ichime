import Foundation

extension ApiClient {
  public func getSeries(
    seriesID: Int
  ) async throws(ApiClientError) -> SeriesFull {
    try await sendRequest(
      endpoint: "/series/\(seriesID)",
      queryItems: []
    )
  }
}
