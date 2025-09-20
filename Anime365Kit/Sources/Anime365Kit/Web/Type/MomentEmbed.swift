import Foundation
import SwiftSoup

public struct VideoSource: Codable {
  public let height: Int
  public let urls: [URL]
}

public struct MomentEmbed {
  public let videoURL: URL

  init(htmlElement: Element) throws(WebClientTypeNormalizationError) {
    guard let dataSourcesJson = try? htmlElement.select("#main-video").first()?.attr("data-sources") else {
      throw .failedCreatingDTOFromHTMLElement(
        "Could extract `data-sources` JSON string from HTML element"
      )
    }

    let jsonDecoder = JSONDecoder()

    guard let data = dataSourcesJson.data(using: .utf8) else {
      throw .failedCreatingDTOFromHTMLElement(
        "Failed to create data from `data-sources` JSON string"
      )
    }

    guard let videoSources = try? jsonDecoder.decode([VideoSource].self, from: data) else {
      throw .failedCreatingDTOFromHTMLElement(
        "`data-sources` JSON is not valid"
      )
    }

    guard
      let videoSourceUrl = videoSources.filter({ !$0.urls.isEmpty }).sorted(by: { $1.height > $0.height }).first?.urls
        .first
    else {
      throw .failedCreatingDTOFromHTMLElement(
        "`data-sources` JSON contains empty array or array of invalid sources"
      )
    }

    self.videoURL = videoSourceUrl
  }
}
