import Foundation
import SwiftSoup

extension WebClient {
  @concurrent
  public func markEpisodeAsWatched(
    translationID: Int
  ) async throws(WebClientError) -> Void {
    _ = try await self.sendRequest(
      "/translations/watched/\(translationID)",
      queryItems: [],
      formData: [],
    )
  }
}
