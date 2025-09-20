import Foundation
import SwiftSoup

public enum GetProfileError: Error {
  case unknownError
  case authenticationRequired
}

extension WebClient {
  public func getProfile() async throws(GetProfileError) -> Profile {
    var html: String

    do {
      html = try await self.sendRequest(
        "/users/profile",
        queryItems: [
          .init(name: "dynpage", value: "1")
        ],
      )
    }
    catch {
      throw .unknownError
    }

    let htmlDocument = try? SwiftSoup.parse(html)

    guard let htmlDocument else {
      throw .unknownError
    }

    let profileIdString = html.firstMatch(of: #/ID аккаунта: (?<accountId>\d+)/#)?.output.accountId

    guard let profileIdString else {
      self.logNormalizationError(of: Profile.self, message: "Could not find account ID on page")

      throw .unknownError
    }

    guard let profileId = Int(profileIdString) else {
      self.logNormalizationError(of: Profile.self, message: "Could not convert account ID to Int")

      throw .unknownError
    }

    guard let name = try? htmlDocument.select("content .m-small-title").first()?.text() else {
      self.logNormalizationError(of: Profile.self, message: "Could not find name on page")

      throw .unknownError
    }

    guard
      let avatarSrc = try? htmlDocument.select("content .card-image.hide-on-small-and-down img").first()?.attr("src")
    else {
      self.logNormalizationError(of: Profile.self, message: "Could not find avatar on page")

      throw .unknownError
    }

    let avatarURL = self.baseURL.appendingPathComponent(avatarSrc)

    return .init(id: profileId, name: name, avatarURL: avatarURL)
  }
}
