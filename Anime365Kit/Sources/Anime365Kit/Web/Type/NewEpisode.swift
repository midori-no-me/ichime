import Foundation
import SwiftSoup

public struct NewEpisode: Sendable {
  public let seriesId: Int
  public let seriesPosterURL: URL
  public let seriesTitleRu: String
  public let seriesTitleRomaji: String
  public let episodeId: Int
  public let episodeNumberLabel: String
  public let episodeUpdateType: String

  init(htmlElement: Element, anime365BaseURL: URL) throws(WebClientTypeNormalizationError) {
    guard let episodeURLPath = try? htmlElement.select("a[href]").first()?.attr("href") else {
      throw .failedCreatingDTOFromHTMLElement(
        "Could not normalize series and episode IDs because there is no `a[href]` element"
      )
    }

    let episodeURL = anime365BaseURL.appending(path: episodeURLPath)

    if episodeURL.pathComponents.count < 3 {
      throw .failedCreatingDTOFromHTMLElement(
        "Could not normalize series and episode IDs because URL path has less than 3 components"
      )
    }

    let (seriesID, episodeID) = extractIdentifiersFromURL(episodeURL)

    if let seriesID {
      self.seriesId = seriesID
    }
    else {
      throw .failedCreatingDTOFromHTMLElement(
        "Could not normalize series ID because corresponding path segment does not contain ID"
      )
    }

    if let episodeID {
      self.episodeId = episodeID
    }
    else {
      throw .failedCreatingDTOFromHTMLElement(
        "Could not normalize episode ID because corresponding path segment does not contain ID"
      )
    }

    guard
      let backgroundImageURLString = try? htmlElement.select("div.circle[style]")
        .first()?
        .attr("style")
        .firstMatch(of: /background-image: ?url\('(?<url>.+?)'\);/)?.output.url
        .replacingOccurrences(of: ".140x140.1", with: "")
    else {
      throw .failedCreatingDTOFromHTMLElement(
        "Could not normalize poster URL because there is no `div.circle[style]` element with `style` attribute containing `background-image` CSS property"
      )
    }

    self.seriesPosterURL = anime365BaseURL.appending(path: backgroundImageURLString)

    if let seriesTitleRu = try? htmlElement.select("h5.line-1 a").first()?.ownText() {
      self.seriesTitleRu = seriesTitleRu.trim()
    }
    else {
      throw .failedCreatingDTOFromHTMLElement(
        "Could not normalize Russian title because there is no `h5.line-1 a` element"
      )
    }

    if let seriesTitleRomaji = try? htmlElement.select("h6.line-2 a").first()?.ownText() {
      self.seriesTitleRomaji = seriesTitleRomaji.trim()
    }
    else {
      throw .failedCreatingDTOFromHTMLElement(
        "Could not normalize Romaji title because there is no `h6.line-2 a` element"
      )
    }

    if let episodeNumberLabel = try? htmlElement.select("span.online-h").first()?.text() {
      self.episodeNumberLabel = episodeNumberLabel.trim()
    }
    else {
      throw .failedCreatingDTOFromHTMLElement(
        "Could not normalize episode number because there is no `span.online-h` element"
      )
    }

    if let episodeUpdateType = try? htmlElement.select("span.title")
      .first()?
      .text()
      .firstMatch(of: /\((?<updateType>.+?)\)/)?.output.updateType
    {
      self.episodeUpdateType = String(episodeUpdateType).trim()
    }
    else {
      throw .failedCreatingDTOFromHTMLElement(
        "Could not normalize episode number because there is no `span.title` element or it does not contain valid update type string"
      )
    }
  }
}
