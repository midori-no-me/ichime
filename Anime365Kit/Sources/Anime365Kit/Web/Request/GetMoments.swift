import Foundation
import SwiftSoup

public enum GetMomentsError: Error {
  case unknownError
  case authenticationRequired
}

extension WebClient {
  public func getMoments(
    page: Int,
    sort: MomentSorting?
  ) async throws(GetMomentsError) -> [MomentPreview] {
    var html: String

    var queryItems: [URLQueryItem] = []

    if page == 1 {
      queryItems.append(.init(name: "dynpage", value: "1"))
    }
    else {
      queryItems.append(.init(name: "ajaxPage", value: "yw_moments_all"))
      queryItems.append(.init(name: "ajaxPageMode", value: "more"))
      queryItems.append(.init(name: "moments-page", value: "\(page)"))
    }

    if let sort {
      queryItems.append(.init(name: "MomentsFilter[sort]", value: sort.rawValue))
    }

    do {
      html = try await self.sendRequest(
        "/moments/index",
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
      (try? htmlDocument.select("#yw_moments_all div.m-moment").array().compactMap {
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
