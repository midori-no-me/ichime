import Foundation
import SwiftSoup

public struct MomentPreview: Sendable {
  public let momentId: Int
  public let coverURL: URL
  public let momentTitle: String
  public let sourceDescription: String
  public let duration: Duration

  init(htmlElement: Element, anime365BaseURL: URL) throws(WebClientTypeNormalizationError) {
    if let momentTitle = try? htmlElement.select(".m-moment__title a").first()?.text() {
      self.momentTitle = momentTitle.trimmingCharacters(in: .whitespaces)
    }
    else {
      throw .failedCreatingDTOFromHTMLElement(
        "Could not normalize moment title because there is no `.m-moment__title a` element"
      )
    }

    if let sourceDescription = try? htmlElement.select(".m-moment__episode").first()?.text() {
      self.sourceDescription = sourceDescription.trimmingCharacters(in: .whitespaces)
    }
    else {
      throw .failedCreatingDTOFromHTMLElement(
        "Could not normalize source description because there is no `.m-moment__episode` element"
      )
    }

    guard
      let previewURLString = try? htmlElement.select(".m-moment__thumb.a img[src]")
        .first()?
        .attr("src")
        .trimmingCharacters(in: .whitespaces)
        .replacingOccurrences(of: ".320x180", with: ".1280x720")
        .replacing(/\?.+$/, with: "")
    else {
      throw .failedCreatingDTOFromHTMLElement(
        "Could not normalize cover URL because there is no `.m-moment__thumb.a img[src]` element"
      )
    }

    self.coverURL = anime365BaseURL.appending(path: previewURLString)

    if let momentIdString = try? htmlElement.select(".m-moment__title a[href]").first()?.attr("href").firstMatch(
      of: /\/moments\/(?<id>[0-9]+)/
    )?.output.id.trimmingCharacters(in: .whitespaces), let momentId = Int(momentIdString) {
      self.momentId = momentId
    }
    else {
      throw .failedCreatingDTOFromHTMLElement(
        "Could not normalize moment ID because there is no `.m-moment__title a` element with `href` attribute, or `href` attribute contains unsupported path, or ID is not a valid number"
      )
    }

    if let durationString = try? htmlElement.select(".m-moment__duration").first()?.text(),
      let duration = Self.convertStringToDuration(durationString: durationString.trimmingCharacters(in: .whitespaces))
    {
      self.duration = duration
    }
    else {
      throw .failedCreatingDTOFromHTMLElement(
        "Could not normalize moment duration because there is no `.m-moment__duration` element"
      )
    }
  }

  private static func convertStringToDuration(durationString: String) -> Duration? {
    let parts = durationString.split(separator: ":").compactMap { Int($0) }

    switch parts.count {
    case 2:  // mm:ss
      return .seconds(parts[0] * 60 + parts[1])

    case 3:  // hh:mm:ss
      return .seconds(parts[0] * 3600 + parts[1] * 60 + parts[2])

    default:
      return nil
    }
  }
}
