import Foundation
import SwiftSoup

public enum GetMomentEmbedError: Error {
  case unknownError
  case authenticationRequired
}

extension WebClient {
  public func getMomentEmbed(momentID: Int) async throws(GetMomentEmbedError)
    -> MomentEmbed
  {
    var html: String

    do {
      html = try await self.sendRequest(
        "/moments/embed/\(momentID)",
        queryItems: [],
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
