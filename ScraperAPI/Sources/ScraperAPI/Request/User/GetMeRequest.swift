//
//  GetMeRequest.swift
//
//
//  Created by Nikita Nafranets on 24.01.2024.
//

import Foundation
import SwiftSoup

public extension ScraperAPI.Request {
    struct GetMeRequest: ScraperHTMLRequest {
        public typealias ResponseType = ScraperAPI.Types.User
        
        public func getEndpoint() -> String {
            "users/profile"
        }
        
        public func getQueryItems() -> [URLQueryItem] {
            [URLQueryItem(name: "dynpage", value: "1")]
        }
        
        public func getFormData() -> [String: String]? {
            nil
        }
        
        public func parseResponse(html: String, baseURL: URL) throws -> ScraperAPI.Types.User {
            guard let document = try? SwiftSoup.parseBodyFragment(html), let content = try? document.select("content").first() else {
                logger.error("\(String(describing: GetMeRequest.self)): cannot parse document")
                throw ScraperAPI.APIClientError.parseError
            }
            
            guard let user = try? ScraperAPI.Types.User(from: content, baseURL: baseURL) else {
                logger.error("\(String(describing: GetMeRequest.self)): cannot parse user")
                throw ScraperAPI.APIClientError.parseError
            }
            
            return user
        }
    }
}
