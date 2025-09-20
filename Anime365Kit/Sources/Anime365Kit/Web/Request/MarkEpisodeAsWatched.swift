import Foundation
import SwiftSoup

public enum MarkEpisodeAsWatchedError: Error {
  case unknownError
  case authenticationRequired
}

extension WebClient {
  public func markEpisodeAsWatched(
    translationID: Int
  ) async throws(MarkEpisodeAsWatchedError) -> Void {
    do {
      _ = try await self.sendRequest(
        "/translations/watched/\(translationID)",
        queryItems: [],
        formData: [],
      )
    }
    catch {
      throw .unknownError
    }
  }
}
