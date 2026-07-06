import Foundation
import SwiftSoup

extension WebClient {
  public func getMomentDetails(momentID: Int) async throws(WebClientError)
    -> MomentDetails
  {
    let html = try await self.sendRequest(
      "/moments/\(momentID)",
      queryItems: [],
    )

    let htmlDocument = try? SwiftSoup.parse(html)

    guard let htmlDocument else {
      throw .couldNotParseHtml
    }

    if html.contains("Вход или регистрация") || html.contains("Вход - Anime 365") {
      throw .authenticationRequired
    }

    do {
      return try .init(htmlElement: htmlDocument, anime365BaseURL: self.baseURL)
    }
    catch {
      if case WebClientTypeNormalizationError.failedCreatingDTOFromHTMLElement(let errorMessage) = error {
        self.logNormalizationError(of: AnimeListEntry.self, message: errorMessage)
      }

      throw .couldNotParseHtml
    }
  }
}
