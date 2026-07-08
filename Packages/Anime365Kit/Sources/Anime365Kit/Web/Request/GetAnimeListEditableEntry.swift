import Foundation
import SwiftSoup

extension WebClient {
  @concurrent
  public func getAnimeListEditableEntry(seriesID: Int) async throws(WebClientError)
    -> AnimeListEditableEntry
  {
    let queryItems: [URLQueryItem] = [
      .init(name: "mode", value: "mini")
    ]

    let html = try await self.sendRequest(
      "/animelist/edit/\(seriesID)",
      queryItems: queryItems,
    )

    return try self.parseHTML(html) { htmlDocument in
      if html.contains("Вход или регистрация") || html.contains("Вход - Anime 365") {
        throw WebClientError.authenticationRequired
      }

      if html.contains("Добавить в список") {
        return .createNotInList()
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
