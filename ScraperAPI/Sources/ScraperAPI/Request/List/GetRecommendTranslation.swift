//
//  File.swift
//
//
//  Created by Nikita Nafranets on 08.04.2024.
//

import Foundation
import SwiftSoup

public extension ScraperAPI.Request {
    struct GetRecommendTranslation: ScraperHTMLRequest {
        public typealias ResponseType = Int
        let episodeURL: String

        public init(episodeURL url: String) {
            episodeURL = url
        }

        public func getEndpoint() -> String {
            let components = episodeURL.components(separatedBy: "/")
            let trimmedComponents = components.dropLast()
            let url = URL(string: trimmedComponents.joined(separator: "/"))!
            return url.path()
        }

        public func getQueryItems() -> [URLQueryItem] {
            [.init(name: "dynpage", value: "1")]
        }

        public func getFormData() -> [URLQueryItem] {
            []
        }

        public func parseResponse(
            html: String,
            baseURL: URL
        ) throws -> Int {
            do {
                let fragment = try SwiftSoup.parseBodyFragment(html, baseURL.absoluteString)
                let selectedTranslation = try fragment.select(".m-select-translation-list .current")

                let url = try selectedTranslation.attr("href")

                let partWithId = url.components(separatedBy: "/").last ?? ""
                let translationId = getId(from: partWithId)

                if translationId == 0 {
                    throw ScraperAPI.APIClientError.parseError
                }

                return translationId
            } catch {
                throw ScraperAPI.APIClientError.parseError
            }
        }
    }
}
