import Foundation
import SwiftSoup

public struct MomentDetails: Sendable {
  public let seriesID: Int
  public let seriesTitle: String
  public let episodeID: Int

  init(htmlElement: Element, anime365BaseURL: URL) throws(WebClientTypeNormalizationError) {
    guard let linkElements = try? htmlElement.select(".m-moment-player h3 a[href]") else {
      throw .failedCreatingDTOFromHTMLElement(
        "Could not find `.m-moment-player h3 a` HTML element"
      )
    }

    if linkElements.count != 2 {
      throw .failedCreatingDTOFromHTMLElement(
        "There should only be 2 links in `.m-moment-player h3 a` HTML element"
      )
    }

    guard let episodeHref = try? linkElements[0].attr("href") else {
      throw .failedCreatingDTOFromHTMLElement(
        "There should only be 2 links in `.m-moment-player h3 a` HTML element"
      )
    }

    let (seriesID, episodeID) = extractIdentifiersFromURL(anime365BaseURL.appending(path: episodeHref))

    guard let seriesID else {
      throw .failedCreatingDTOFromHTMLElement(
        "Series ID is not valid"
      )
    }

    guard let episodeID else {
      throw .failedCreatingDTOFromHTMLElement(
        "Episode ID is not valid"
      )
    }

    self.seriesID = seriesID
    self.episodeID = episodeID

    guard let seriesTitle = try? linkElements[1].text().trimmingCharacters(in: .whitespacesAndNewlines) else {
      throw .failedCreatingDTOFromHTMLElement(
        "There should only be 2 links in `.m-moment-player h3 a` HTML element"
      )
    }

    self.seriesTitle = seriesTitle
  }
}
