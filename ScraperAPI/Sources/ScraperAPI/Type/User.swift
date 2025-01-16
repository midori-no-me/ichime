import Foundation
import SwiftSoup

extension ScraperAPI.Types {
  public struct User: Codable {
    public let id: Int
    public let username: String
    public let avatarURL: URL
    public let subscribed: Bool

    init(id: Int, username: String, avatarURL: URL, subscribed: Bool) {
      self.id = id
      self.username = username
      self.avatarURL = avatarURL
      self.subscribed = subscribed
    }

    init(from element: Element, baseURL: URL) throws {
      guard let idString = try? element.text().firstMatch(of: #/ID аккаунта: (\d+)/#)?.output.1,
        let id = Int(idString),
        let avatarSrc = try? element.select(".card-image.hide-on-small-and-down img").first()?.attr(
          "src"
        ),
        let username = try? element.select(".m-small-title").first()?.text(),
        let subscribeOut = try? element.text().contains(#/Не оплачена/#)
      else {
        throw ScraperAPI.APIClientError.parseError
      }

      let avatarURL = baseURL.appending(path: avatarSrc.dropFirst())
      self.init(id: id, username: username, avatarURL: avatarURL, subscribed: !subscribeOut)
    }
  }
}
