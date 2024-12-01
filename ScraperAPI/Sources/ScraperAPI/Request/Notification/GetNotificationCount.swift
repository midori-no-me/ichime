//
//  GetNotificationCount.swift
//
//
//  Created by Nikita Nafranets on 24.01.2024.
//

import Foundation
import SwiftSoup

extension ScraperAPI.Request {
  public struct GetNotificationCount: ScraperHTMLRequest {
    public typealias ResponseType = Int

    public init() {}

    public func getEndpoint() -> String {
      ""
    }

    public func getQueryItems() -> [URLQueryItem] {
      []
    }

    public func getFormData() -> [URLQueryItem] {
      []
    }

    public func parseResponse(html: String, baseURL _: URL) throws -> Int {
      do {
        let doc: Document = try SwiftSoup.parse(html)
        guard let counterElement = try doc.select("[href=/notifications/index]").first(),
          let match = try counterElement.text().firstMatch(of: #/(?<count>\d+)/#),
          let counter = Int(match.output.count)
        else {
          return 0
        }

        return counter
      }
      catch {
        logger
          .error(
            "\(String(describing: GetNotificationCount.self)): cannot parse or get counter, \(error.localizedDescription, privacy: .public)"
          )
        return 0
      }
    }
  }
}
