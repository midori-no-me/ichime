import Foundation
import SwiftSoup

extension ScraperAPI.Request {
  public struct GetMomentsByEpisode: ScraperHTMLRequest {
    public typealias ResponseType = [ScraperAPI.Types.Moment]

    let id: Int
    let page: Int

    public init(episodeId id: Int, page: Int = 1) {
      self.id = id
      self.page = page
    }

    public func getEndpoint() -> String {
      "moments/listByEpisode/\(id)"
    }

    public func getQueryItems() -> [URLQueryItem] {
      var query: [URLQueryItem] = []

      if page == 1 {
        query.append(.init(name: "dynpage", value: "1"))
      }
      else {
        query.append(.init(name: "ajaxPage", value: "yw_moments_episodes"))
        query.append(.init(name: "ajaxPageMode", value: "more"))
        query.append(.init(name: "moments-page", value: "\(page)"))
      }

      return query
    }

    public func getFormData() -> [URLQueryItem] {
      []
    }

    public func parseResponse(html: String, baseURL: URL) throws -> [ScraperAPI.Types.Moment] {
      do {
        let fragment = try SwiftSoup.parseBodyFragment(html, baseURL.absoluteString)

        return try fragment.select(".m-moment__card")
          .map { try ScraperAPI.Types.Moment(from: $0, baseURL: baseURL) }

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
