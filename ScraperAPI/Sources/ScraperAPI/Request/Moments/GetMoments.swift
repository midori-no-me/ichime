import Foundation
import SwiftSoup

extension ScraperAPI.Request {
  public struct GetMoments: ScraperHTMLRequest {
    public typealias ResponseType = [ScraperAPI.Types.Moment]

    let page: Int
    let filter: MomentFilter

    public init(page: Int = 1, filter: MomentFilter = .init()) {
      self.page = page
      self.filter = filter
    }

    public func getEndpoint() -> String {
      "moments/index"
    }

    public func getQueryItems() -> [URLQueryItem] {
      var query: [URLQueryItem] = [
        .init(name: "yt0", value: nil),
        .init(name: "MomentsFilter[categoryId]", value: filter.category.rawValue),
        .init(name: "MomentsFilter[sort]", value: filter.sort.rawValue),
        .init(name: "MomentsFilter[duration]", value: filter.duration.rawValue),
      ]

      if page == 1 {
        query.append(.init(name: "dynpage", value: "1"))
      }
      else {
        query.append(.init(name: "ajaxPage", value: "yw_moments_all"))
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

    public struct MomentFilter {
      public let category: MomentType
      public let sort: MomentSorting
      public let duration: MomentDuration

      public init(
        category: MomentType = .all,
        sort: MomentSorting = .newest,
        duration: MomentDuration = .any
      ) {
        self.category = category
        self.sort = sort
        self.duration = duration
      }
    }

    public enum MomentType: String {
      case all = ""
      case justFunny = "1"
      case funnyMoment = "2"
      case sadMoment = "3"
      case touchingMoment = "4"
      case openingEnding = "5"
    }

    public enum MomentSorting: String {
      case newest = "new"  // По умолчанию
      case oldest = "old"
      case popular
    }

    public enum MomentDuration: String {
      case any = ""
      case upTo15Seconds = "0-15"
      case upTo30Seconds = "0-30"
      case upTo70Seconds = "0-70"
      case upTo2Minutes = "0-120"
      case oneAndHalfMinute = "80-100"
      case from5To80Seconds = "5-80"
      case over1Minute = "60-"
      case over2Minutes = "120-"
    }
  }
}
