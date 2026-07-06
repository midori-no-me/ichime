import Foundation
import SwiftSoup

extension WebClient {
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

    let htmlDocument = try? SwiftSoup.parse(html)

    guard let htmlDocument else {
      throw .couldNotParseHtml
    }

    if html.contains("Вход или регистрация") || html.contains("Вход - Anime 365") {
      throw .authenticationRequired
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
