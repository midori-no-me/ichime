import Foundation
import SwiftSoup

extension ScraperAPI.Types {
  public struct WatchShow {
    public let episodeId: Int
    public let showId: Int
    public let showName: Name
    public let imageURL: URL
    public let episodeTitle: String
    public let updateType: String

    init(from htmlElement: Element, baseURL: URL) throws {
      let episodeLink = try htmlElement.getElementsByTag("a").first()?.attr("href") ?? ""

      guard let (showID, episodeID, _) = extractIDs(from: episodeLink) else {
        throw ScraperAPI.APIClientError.parseError
      }

      let image = try htmlElement.select(".collection-item.avatar .circle").imageBackground()
        .replacingOccurrences(of: ".140x140.1", with: "").dropFirst()

      guard let episodeNumberText = try htmlElement.select("span.online-h").first()?.text() else {
        throw ScraperAPI.APIClientError.parseError
      }

      let episode = Episode(id: episodeID, episodeText: episodeNumberText)

      guard let ruName = try Self.extractNameFromHTML(from: htmlElement.select("h5.line-1 a").first()) else {
        throw ScraperAPI.APIClientError.parseError
      }

      guard let enName = try Self.extractNameFromHTML(from: htmlElement.select("h6.line-2 a").first()) else {
        throw ScraperAPI.APIClientError.parseError
      }

      guard let episodeTitleAndUpdateType = try htmlElement.select("span.title").first()?.text() else {
        throw ScraperAPI.APIClientError.parseError
      }

      guard let updateType = episodeTitleAndUpdateType.firstMatch(of: /\((.+)\)/) else {
        throw ScraperAPI.APIClientError.parseError
      }

      self.episodeId = episodeID
      self.showId = showID
      self.showName = Name(ru: ruName, romaji: enName)
      self.imageURL = baseURL.appending(path: image)
      self.episodeTitle = episodeNumberText
      self.updateType = String(updateType.1)
    }

    private static func extractNameFromHTML(from element: Element?) -> String? {
      guard let element else {
        return nil
      }
      return element.ownText()
    }
  }
}
