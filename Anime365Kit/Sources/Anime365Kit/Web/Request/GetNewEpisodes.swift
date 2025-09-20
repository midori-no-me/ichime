import Foundation
import SwiftSoup

public enum GetNewEpisodesError: Error {
  case unknownError
  case authenticationRequired
}

extension WebClient {
  public func getNewEpisodes(page: Int) async throws(GetNewEpisodesError) -> [NewEpisode] {
    var html: String

    var queryItems: [URLQueryItem] = [
      .init(name: "ajax", value: "m-index-personal-episodes")
    ]

    if page > 1 {
      queryItems.append(URLQueryItem(name: "pageP", value: String(page)))
    }

    do {
      html = try await self.sendRequest(
        "/",
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
      (try? htmlDocument.select("#m-index-personal-episodes div.m-new-episode").array().compactMap {
        do {
          return try .init(htmlElement: $0, anime365BaseURL: self.baseURL)
        }
        catch {
          if case WebClientTypeNormalizationError.failedCreatingDTOFromHTMLElement(let errorMessage) = error {
            self.logNormalizationError(of: NewEpisode.self, message: errorMessage)
          }

          return nil
        }
      }) ?? []
  }
}
