import Foundation
import SwiftSoup

extension WebClient {
  @concurrent
  public func getMomentEmbed(momentID: Int) async throws(WebClientError)
    -> MomentEmbed
  {
    let html = try await self.sendRequest(
      "/moments/embed/\(momentID)",
      queryItems: [],
    )

    return try self.parseHTML(html) { htmlDocument in
      if html.contains("Вход или регистрация") || html.contains("Вход - Anime 365") {
        throw WebClientError.authenticationRequired
      }

      do {
        return try .init(htmlElement: htmlDocument)
      }
      catch {
        if case WebClientTypeNormalizationError.failedCreatingDTOFromHTMLElement(let errorMessage) = error {
          self.logNormalizationError(of: AnimeListEntry.self, message: errorMessage)
        }

        throw WebClientError.couldNotParseHtml
      }
    }
  }
}
