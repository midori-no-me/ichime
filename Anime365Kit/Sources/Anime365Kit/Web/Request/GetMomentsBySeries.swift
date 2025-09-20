import Foundation
import SwiftSoup

public enum GetMomentsBySeriesError: Error {
  case unknownError
  case authenticationRequired
}

extension WebClient {
  public func getMomentsBySeries(
    seriesId: Int,
    page: Int,
  ) async throws(GetMomentsBySeriesError) -> [MomentPreview] {
    var html: String

    var queryItems: [URLQueryItem] = []

    if page == 1 {
      queryItems.append(.init(name: "dynpage", value: "1"))
    }
    else {
      queryItems.append(.init(name: "ajaxPage", value: "yw_moments_by_series"))
      queryItems.append(.init(name: "ajaxPageMode", value: "more"))
      queryItems.append(.init(name: "moments-page", value: "\(page)"))
    }

    do {
      html = try await self.sendRequest(
        "/moments/listBySeries/\(seriesId)",
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
      (try? htmlDocument.select("#yw_moments_by_series div.m-moment").array().compactMap {
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
