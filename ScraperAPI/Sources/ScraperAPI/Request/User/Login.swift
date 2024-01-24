//
//  LoginRequest.swift
//
//
//  Created by Nikita Nafranets on 24.01.2024.
//

import Foundation
import SwiftSoup

public extension ScraperAPI.Request {
    struct Login: ScraperHTMLRequest {
        public typealias ResponseType = ScraperAPI.Types.User
        
        private let username: String
        private let password: String
        
        public func getEndpoint() -> String {
            "users/login"
        }
        
        public func getQueryItems() -> [URLQueryItem] {
            []
        }
        
        public func getFormData() -> [String: String]? {
            [
                "LoginForm[username]": username,
                "LoginForm[password]": password,
                "dynpage": "1",
                "yt0": "",
            ]
        }
        
        public func parseResponse(html: String, baseURL: URL) throws -> ScraperAPI.Types.User {
            if html.contains(#/Неверный E-mail или пароль/#) {
                throw ScraperAPI.APIClientError.invalidCredentials
            }
            
            guard let document = try? SwiftSoup.parseBodyFragment(html), let content = try? document.select("content").first() else {
                logger.error("\(String(describing: Login.self)): cannot parse document")
                throw ScraperAPI.APIClientError.parseError
            }
            
            guard let user = try? ScraperAPI.Types.User(from: content, baseURL: baseURL) else {
                logger.error("\(String(describing: Login.self)): cannot parse user")
                throw ScraperAPI.APIClientError.parseError
            }
            
            return user
        }
    }
}
