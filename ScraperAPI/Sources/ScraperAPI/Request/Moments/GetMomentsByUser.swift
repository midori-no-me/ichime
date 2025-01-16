import Foundation
import SwiftSoup

extension ScraperAPI.Request {
  public struct GetMomentsByUser: ScraperHTMLRequest {
    public typealias ResponseType = [ScraperAPI.Types.Moment]

    let id: Int
    let page: Int

    public init(userId id: Int, page: Int = 1) {
      self.id = id
      self.page = page
    }

    public func getEndpoint() -> String {
      "users/\(self.id)/moments"
    }

    public func getQueryItems() -> [URLQueryItem] {
      var query: [URLQueryItem] = []

      if self.page == 1 {
        query.append(.init(name: "dynpage", value: "1"))
      }
      else {
        query.append(.init(name: "ajaxPage", value: "yw_moments_by_user"))
        query.append(.init(name: "ajaxPageMode", value: "more"))
        query.append(.init(name: "moments-page", value: "\(self.page)"))
      }

      return query
    }

    public func getFormData() -> [URLQueryItem] {
      []
    }

    public func parseResponse(html: String, baseURL: URL) throws -> [ScraperAPI.Types.Moment] {
      do {
        let fragment = try SwiftSoup.parseBodyFragment(html, baseURL.absoluteString)
        let userName = try fragment.select(".m-small-title").text(trimAndNormaliseWhitespace: true)
        let userAvatar = try fragment.select(".card-image.hide-on-small-and-down img").attr("src")
        return try fragment.select(".m-moment__card")
          .map {
            try ScraperAPI.Types.Moment(
              from: $0,
              withUser: .init(
                id: self.id,
                name: userName,
                avatar: baseURL.appending(path: userAvatar)
              ),
              baseURL: baseURL
            )
          }
      }
      catch {
        logger
          .error(
            "\(String(describing: Self.self)): cannot parse html, \(error.localizedDescription, privacy: .public)"
          )
        throw ScraperAPI.APIClientError.parseError
      }
    }
  }
}
