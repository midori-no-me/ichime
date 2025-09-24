import Foundation
import SwiftSoup

extension WebClient {
  public func getAnimeListEditableEntry(seriesID: Int) async throws(WebClientError)
    -> AnimeListEditableEntry
  {
    var html: String

    let queryItems: [URLQueryItem] = [
      .init(name: "mode", value: "mini")
    ]

    html = try await self.sendRequest(
      "/animelist/edit/\(seriesID)",
      queryItems: queryItems,
    )

    let htmlDocument = try? SwiftSoup.parse(html)

    guard let htmlDocument else {
      throw .couldNotParseHtml
    }

    if html.contains("Вход или регистрация") || html.contains("Вход - Anime 365") {
      throw .authenticationRequired
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

      throw .couldNotParseHtml
    }
  }
}
