import Foundation
import SwiftSoup

extension WebClient {
  @concurrent
  public func getAnimeList(userId: Int, category: AnimeListCategory) async throws(WebClientError) -> [AnimeListEntry] {
    let queryItems: [URLQueryItem] = [
      .init(name: "dynpage", value: "1")
    ]

    let html = try await self.sendRequest(
      "/users/\(userId)/list/\(category.webPath)",
      queryItems: queryItems,
    )

    return try self.parseHTML(html) { htmlDocument in
      if html.contains("Вход или регистрация") || html.contains("Вход - Anime 365") {
        throw WebClientError.authenticationRequired
      }

      return
        (try? htmlDocument.select("div.card.m-animelist-card tr.m-animelist-item").array().compactMap {
          do {
            return try .init(htmlElement: $0)
          }
          catch {
            if case WebClientTypeNormalizationError.failedCreatingDTOFromHTMLElement(let errorMessage) = error {
              self.logNormalizationError(of: AnimeListEntry.self, message: errorMessage)
            }

            return nil
          }
        }) ?? []
    }
  }
}
