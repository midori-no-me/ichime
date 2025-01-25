import Foundation

extension ApiClient {
  public func getSeries(
    seriesId: Int
  ) async throws -> Series {
    try await sendRequest(
      endpoint: "/series/\(seriesId)",
      queryItems: []
    )
  }
}
