import Foundation
import SwiftSoup

public struct AnimeListEntry {
  public let seriesId: Int
  public let seriesTitleFull: String
  public let episodesWatched: Int
  public let episodesTotal: Int?
  public let score: Int?

  init(htmlElement: Element) throws(WebClientTypeNormalizationError) {
    if let seriesIDString = try? htmlElement.attr("data-id"), let seriesID = Int(seriesIDString) {
      self.seriesId = seriesID
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

    if let scoreString = try? htmlElement.select("td[data-name=\"score\"]").first()?.text() {
      self.score = Int(scoreString)
    }
    else {
      throw .failedCreatingDTOFromHTMLElement(
        "Could not normalize score string because there is no `td[data-name=\"score\"]` element"
      )
    }
  }
}
