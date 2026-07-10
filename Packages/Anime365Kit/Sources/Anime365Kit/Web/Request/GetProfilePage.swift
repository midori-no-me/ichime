import Foundation
import SwiftSoup

extension WebClient {
  @concurrent
  public func getProfilePage() async throws(WebClientError) -> ProfilePage {
    let html = try await self.sendRequest(
      "/users/profile",
      queryItems: [
        .init(name: "dynpage", value: "1")
      ],
    )

    return try self.parseHTML(html) { htmlDocument in
      if html.contains("Вход по паролю") {
        throw WebClientError.authenticationRequired
      }

      return .init(
        profile: try self.getProfile(fromProfilePageHTML: html, htmlDocument: htmlDocument),
        playerChannelSettings: try? self.getProfilePlayerChannelSettings(fromProfilePageHTMLDocument: htmlDocument)
      )
    }
  }

  private func getProfile(
    fromProfilePageHTML html: String,
    htmlDocument: Document
  ) throws(WebClientError) -> Profile {
    let profileIDString = html.firstMatch(of: #/ID аккаунта: (?<accountID>\d+)/#)?.output.accountID

    guard let profileIDString else {
      self.logNormalizationError(of: Profile.self, message: "Could not find account ID on page")

      throw .couldNotParseHtml
    }

    guard let profileID = Int(profileIDString) else {
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

    return .init(id: profileID, name: name, avatarURL: avatarURL)
  }

  private func getProfilePlayerChannelSettings(
    fromProfilePageHTMLDocument htmlDocument: Document
  ) throws(WebClientError) -> ProfilePlayerChannelSettings {
    let playerChannels =
      (try? htmlDocument.select("#Users_useOtherServers option").array().compactMap { option -> PlayerChannel? in
        guard
          let id = try? option.attr("value"),
          !id.isEmpty,
          let name = try? option.text(),
          !name.isEmpty
        else {
          return nil
        }

        return .init(id: id, name: name)
      }) ?? []

    guard !playerChannels.isEmpty else {
      self.logNormalizationError(
        of: ProfilePlayerChannelSettings.self,
        message: "Could not find player channel options on page"
      )

      throw .couldNotParseHtml
    }

    guard
      let selectedPlayerChannelID = try? htmlDocument
        .select("#Users_useOtherServers option[selected]")
        .first()?
        .attr("value"),
      let playerChannel = playerChannels.first(where: { $0.id == selectedPlayerChannelID })
    else {
      self.logNormalizationError(
        of: ProfilePlayerChannelSettings.self,
        message: "Could not find selected player channel on page"
      )

      throw .couldNotParseHtml
    }

    return .init(playerChannel: playerChannel, playerChannels: playerChannels)
  }
}
