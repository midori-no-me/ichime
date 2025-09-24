import Foundation
import SwiftSoup

extension WebClient {
  public func getProfile() async throws(WebClientError) -> Profile {
    let html = try await self.sendRequest(
      "/users/profile",
      queryItems: [
        .init(name: "dynpage", value: "1")
      ],
    )

    let htmlDocument = try? SwiftSoup.parse(html)

    guard let htmlDocument else {
      throw .couldNotParseHtml
    }

    let profileIdString = html.firstMatch(of: #/ID аккаунта: (?<accountId>\d+)/#)?.output.accountId

    guard let profileIdString else {
      self.logNormalizationError(of: Profile.self, message: "Could not find account ID on page")

      throw .couldNotParseHtml
    }

    guard let profileId = Int(profileIdString) else {
      self.logNormalizationError(of: Profile.self, message: "Could not convert account ID to Int")

      throw .couldNotParseHtml
    }

    guard let name = try? htmlDocument.select("content .m-small-title").first()?.text() else {
      self.logNormalizationError(of: Profile.self, message: "Could not find name on page")

      throw .couldNotParseHtml
    }

    guard
      let avatarSrc = try? htmlDocument.select("content .card-image.hide-on-small-and-down img").first()?.attr("src")
    else {
      self.logNormalizationError(of: Profile.self, message: "Could not find avatar on page")

      throw .couldNotParseHtml
    }

    let avatarURL = self.baseURL.appendingPathComponent(avatarSrc)

    return .init(id: profileId, name: name, avatarURL: avatarURL)
  }
}
