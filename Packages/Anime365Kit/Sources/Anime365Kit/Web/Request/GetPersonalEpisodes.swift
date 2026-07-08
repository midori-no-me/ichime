import Foundation
import SwiftSoup

extension WebClient {
  @concurrent
  public func getPersonalEpisodes(page: Int) async throws(WebClientError) -> [NewPersonalEpisode] {
    var queryItems: [URLQueryItem] = [
      .init(name: "ajax", value: "m-index-personal-episodes")
    ]

    if page > 1 {
      queryItems.append(URLQueryItem(name: "pageP", value: String(page)))
    }

    let html = try await self.sendRequest(
      "/",
      queryItems: queryItems,
    )

    return try self.parseHTML(html) { htmlDocument in
      if html.contains("Вход или регистрация") || html.contains("Вход - Anime 365") {
        throw WebClientError.authenticationRequired
      }

      return
        (try? htmlDocument.select("#m-index-personal-episodes div.m-new-episode").array().compactMap {
          do {
            return try .init(htmlElement: $0, anime365BaseURL: self.baseURL)
          }
          catch {
            if case WebClientTypeNormalizationError.failedCreatingDTOFromHTMLElement(let errorMessage) = error {
              self.logNormalizationError(of: NewPersonalEpisode.self, message: errorMessage)
            }

            return nil
          }
        }) ?? []
    }
  }
}
