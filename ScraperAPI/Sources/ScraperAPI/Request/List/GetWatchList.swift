//
//  File.swift
//
//
//  Created by Nikita Nafranets on 24.01.2024.
//

import Foundation
import SwiftSoup

public extension ScraperAPI.Request {
    struct GetWatchList: ScraperHTMLRequest {
        public typealias ResponseType = [ScraperAPI.Types.ListByCategory]

        private let userId: Int
        private let type: ScraperAPI.Types.ListCategoryType?

        public init(userId: Int, type: ScraperAPI.Types.ListCategoryType? = nil) {
            self.userId = userId
            self.type = type
        }

        public func getEndpoint() -> String {
            var path = "users/\(userId)/list"
            switch type {
            case .completed:
                path = path + "/completed"
            case .dropped:
                path = path + "/dropped"
            case .onHold:
                path = path + "/onhold"
            case .watching:
                path = path + "/watching"
            case .planned:
                path = path + "/planned"
            case .none:
                break
            }
            return path
        }

        public func getQueryItems() -> [URLQueryItem] {
            [.init(name: "dynpage", value: "1")]
        }

        public func getFormData() -> [URLQueryItem] {
            []
        }

        public func parseResponse(html: String, baseURL: URL) throws -> [ScraperAPI.Types.ListByCategory] {
            do {
                let doc = try SwiftSoup.parseBodyFragment(html)

                let sections = try doc.select(".m-animelist-card")

                if let type, sections.size() == 1 {
                    return try sections.array().map { try ScraperAPI.Types.ListByCategory(from: $0, type: type) }
                }

                return try sections.array().map { try ScraperAPI.Types.ListByCategory(from: $0) }
            } catch {
                logger.error("\(String(describing: Self.self)): cannot parse html, \(error.localizedDescription, privacy: .public)")
                throw ScraperAPI.APIClientError.parseError
            }
        }
    }
}
