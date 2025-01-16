import Foundation
import SwiftSoup

extension ScraperAPI.Request {
  public struct GetNextToWatch: ScraperHTMLRequest {
    public typealias ResponseType = [ScraperAPI.Types.WatchShow]

    private let page: Int

    public init(page: Int = 1) {
      self.page = page
    }

    public func getEndpoint() -> String {
      ""
    }

    public func getQueryItems() -> [URLQueryItem] {
      var query = [
        URLQueryItem(name: "ajax", value: "m-index-personal-episodes")
      ]
      if page > 1 {
        query.append(URLQueryItem(name: "pageP", value: String(page)))
      }
      return query
    }

    public func getFormData() -> [URLQueryItem] {
      []
    }

    public func parseResponse(html: String, baseURL: URL) throws -> [ScraperAPI.Types.WatchShow] {
      do {
        let doc: Document = try SwiftSoup.parse(html)
        guard let watchSection = try doc.getElementById("m-index-personal-episodes") else {
          throw ScraperAPI.APIClientError.parseError
        }

        let elements = try watchSection.select("div.m-new-episode")

        return elements.array().compactMap {
          try? ScraperAPI.Types.WatchShow(from: $0, baseURL: baseURL)
        }
      }
      catch {
        logger
          .error(
            "\(String(describing: Self.self)): cannot parse, \(error.localizedDescription, privacy: .public)"
          )
        throw ScraperAPI.APIClientError.parseError
      }
    }
  }
}
