//
//  File.swift
//  
//
//  Created by Nikita Nafranets on 24.03.2024.
//

import Foundation
import SwiftSoup

public extension ScraperAPI.Request {
    struct GetMomentsByShow: ScraperHTMLRequest {
        public typealias ResponseType = [ScraperAPI.Types.Moment]

        let id: Int
        let page: Int

        public init(showId id: Int, page: Int = 1) {
            self.id = id
            self.page = page
        }

        public func getEndpoint() -> String {
            "moments/listBySeries/\(id)"
        }

        public func getQueryItems() -> [URLQueryItem] {
            var query: [URLQueryItem] = []

            if page == 1 {
                query.append(.init(name: "dynpage", value: "1"))
            } else {
                query.append(.init(name: "ajaxPage", value: "yw_moments_by_series"))
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

            } catch {
                logger
                    .error(
                        "\(String(describing: Self.self)): cannot parse html, \(error.localizedDescription, privacy: .public)"
                    )
                throw ScraperAPI.APIClientError.parseError
            }
        }
    }
}
