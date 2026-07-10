import Foundation
import SwiftSoup

public struct AnimeListEntry: Sendable {
  // MARK: Properties

  public let seriesID: Int
  public let seriesTitleFull: String
  public let episodesWatched: Int
  public let episodesTotal: Int?

  // MARK: Lifecycle

  init(htmlElement: Element) throws(WebClientTypeNormalizationError) {
    if let seriesIDString = try? htmlElement.attr("data-id"), let seriesID = Int(seriesIDString) {
      self.seriesID = seriesID
    }
    else {
      throw .failedCreatingDTOFromHTMLElement("Could not normalize series ID because there is no `[data-id]` attribute")
    }

    if let seriesTitleFull = try? htmlElement.select("a[href]").first()?.text() {
      self.seriesTitleFull = seriesTitleFull.trim()
    }
    else {
      throw .failedCreatingDTOFromHTMLElement("Could not normalize series title because there is no `a[href]` element")
    }

    guard let episodesString = try? htmlElement.select("td[data-name=\"episodes\"]").first()?.text() else {
      throw .failedCreatingDTOFromHTMLElement(
        "Could not normalize episodes string because there is no `td[data-name=\"episodes\"]` element"
      )
    }

    let explodedEpisodesString = episodesString.trim().split(separator: " / ")

    if explodedEpisodesString.count != 2 {
      throw .failedCreatingDTOFromHTMLElement(
        "Episodes string contains \(explodedEpisodesString.count) elements but 2 expected"
      )
    }

    if let episodesWatched = Int(explodedEpisodesString[0]) {
      self.episodesWatched = episodesWatched
    }
    else {
      throw .failedCreatingDTOFromHTMLElement("Episodes watched is not a valid integer")
    }

    self.episodesTotal = Int(explodedEpisodesString[1])
  }
}
