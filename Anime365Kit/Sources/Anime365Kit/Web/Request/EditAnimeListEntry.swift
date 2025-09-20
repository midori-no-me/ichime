import Foundation
import SwiftSoup

public enum EditAnimeListEntryError: Error {
  case unknownError
  case authenticationRequired
}

extension WebClient {
  public func editAnimeListEntry(
    seriesID: Int,
    score: Int,
    episodes: Int,
    status: Int,
    comment: String
  ) async throws(EditAnimeListEntryError) -> Void {
    let formData: [URLQueryItem] = [
      .init(name: "UsersRates[score]", value: String(score)),
      .init(name: "UsersRates[episodes]", value: String(episodes)),
      .init(name: "UsersRates[status]", value: String(status)),
      .init(name: "UsersRates[comment]", value: comment),
    ]

    do {
      _ = try await self.sendRequest(
        "/animelist/edit/\(seriesID)",
        queryItems: [
          .init(name: "mode", value: "mini")
        ],
        formData: formData,
      )
    }
    catch {
      throw .unknownError
    }
  }
}
