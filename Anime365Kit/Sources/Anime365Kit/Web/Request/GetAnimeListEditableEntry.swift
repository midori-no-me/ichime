import Foundation
import SwiftSoup

public enum GetAnimeListEditableEntryError: Error {
  case unknownError
  case authenticationRequired
}

extension WebClient {
  public func getAnimeListEditableEntry(seriesID: Int) async throws(GetAnimeListEditableEntryError)
    -> AnimeListEditableEntry
  {
    var html: String

    let queryItems: [URLQueryItem] = [
      .init(name: "mode", value: "mini")
    ]

    do {
      html = try await self.sendRequest(
        "/animelist/edit/\(seriesID)",
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

      throw .unknownError
    }
  }
}
