import Foundation
import SwiftSoup

public enum GetAnimeListError: Error {
  case unknownError
  case authenticationRequired
}

extension WebClient {
  public func getAnimeList(userId: Int, category: AnimeListCategory) async throws(GetAnimeListError) -> [AnimeListEntry]
  {
    var html: String

    let queryItems: [URLQueryItem] = [
      .init(name: "dynpage", value: "1")
    ]

    do {
      html = try await self.sendRequest(
        "/users/\(userId)/list/\(category.webPath)",
        queryItems: queryItems,
      )
    }
    catch {
      throw .unknownError
    }

    let htmlDocument = try? SwiftSoup.parse(html)

    guard let htmlDocument else {
      throw .unknownError
    }

    if html.contains("Вход или регистрация") {
      throw .authenticationRequired
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
