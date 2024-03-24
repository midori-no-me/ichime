//
//  File.swift
//
//
//  Created by Nikita Nafranets on 24.03.2024.
//

import Foundation
import SwiftSoup

public extension ScraperAPI.Request {
    struct GetMomentEmbed: ScraperHTMLRequest {
        let id: Int

        public init(momentId id: Int) {
            self.id = id
        }

        public func getEndpoint() -> String {
            "moments/embed/\(id)"
        }

        public func getQueryItems() -> [URLQueryItem] {
            []
        }

        public func getFormData() -> [URLQueryItem] {
            []
        }

        public func parseResponse(html: String, baseURL: URL) throws -> ScraperAPI.Types.MomentEmbed {
            do {
                let document = try SwiftSoup.parse(html, baseURL.absoluteString)

                guard let element = try? document.getElementById("main-video") else {
                    throw ScraperAPI.APIClientError.parseError
                }

                return try ScraperAPI.Types.MomentEmbed(from: element)

            } catch {
                logger
                    .error(
                        "\(String(describing: Self.self)): cannot parse html, \(error.localizedDescription, privacy: .public)"
                    )
                throw ScraperAPI.APIClientError.parseError
            }
        }

        public typealias ResponseType = ScraperAPI.Types.MomentEmbed
    }
}
