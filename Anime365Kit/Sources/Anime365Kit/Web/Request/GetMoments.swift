import Foundation
import SwiftSoup

extension WebClient {
  public func getMoments(
    page: Int,
    sort: MomentSorting?
  ) async throws(WebClientError) -> [MomentPreview] {
    var queryItems: [URLQueryItem] = []

    if page == 1 {
      queryItems.append(.init(name: "dynpage", value: "1"))
    }
    else {
      queryItems.append(.init(name: "ajaxPage", value: "yw_moments_all"))
      queryItems.append(.init(name: "ajaxPageMode", value: "more"))
      queryItems.append(.init(name: "moments-page", value: "\(page)"))
    }

    if let sort {
      queryItems.append(.init(name: "MomentsFilter[sort]", value: sort.rawValue))
    }

    let html = try await self.sendRequest(
      "/moments/index",
      queryItems: queryItems,
    )

    let htmlDocument = try? SwiftSoup.parse(html)

    guard let htmlDocument else {
      throw .couldNotParseHtml
    }

    if html.contains("Вход или регистрация") || html.contains("Вход - Anime 365") {
      throw .authenticationRequired
    }

    return
      (try? htmlDocument.select("#yw_moments_all div.m-moment").array().compactMap {
        do {
          return try .init(htmlElement: $0, anime365BaseURL: self.baseURL)
        }
        catch {
          if case WebClientTypeNormalizationError.failedCreatingDTOFromHTMLElement(let errorMessage) = error {
            self.logNormalizationError(of: MomentPreview.self, message: errorMessage)
          }

          return nil
        }
      }) ?? []
  }
}
