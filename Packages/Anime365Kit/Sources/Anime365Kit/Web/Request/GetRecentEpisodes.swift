import Foundation
import SwiftSoup

extension WebClient {
  @concurrent
  public func getRecentEpisodes(page: Int) async throws(WebClientError) -> [NewRecentEpisode] {
    let queryItems: [URLQueryItem] = [
      .init(name: "ajax", value: "m-index-recent-episodes")
    ]

    let html = try await self.sendRequest(
      "/page/\(page)",
      queryItems: queryItems,
    )

    return try self.parseHTML(html) { htmlDocument in
      if html.contains("Вход или регистрация") || html.contains("Вход - Anime 365") {
        throw WebClientError.authenticationRequired
      }

      var items: [NewRecentEpisode] = []

      for sectionElement
        in (try? htmlDocument.select("#m-index-recent-episodes .m-new-episodes.collection.with-header").array()) ?? []
      {
        let sectionHeader = try? sectionElement.select("h3").text().trim()

        guard let sectionHeader else {
          self.logNormalizationError(of: NewRecentEpisode.self, message: "Could not find section header")

          continue
        }

        for episodeElement in (try? sectionElement.select("div.m-new-episode").array()) ?? [] {
          do {
            items.append(
              try .init(htmlElement: episodeElement, anime365BaseURL: self.baseURL, sectionTitle: sectionHeader)
            )
          }
          catch {
            if case WebClientTypeNormalizationError.failedCreatingDTOFromHTMLElement(let errorMessage) = error {
              self.logNormalizationError(of: NewRecentEpisode.self, message: errorMessage)
            }

            continue
          }
        }
      }

      return items
    }
  }
}
