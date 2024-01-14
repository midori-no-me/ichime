//
//  Profile.swift
//
//
//  Created by Nikita Nafranets on 14.01.2024.
//

import Foundation
import SwiftSoup

public extension Anime365Scraper {
    /**
     * Структура для работы с профилем
      */
    struct Profile {
        private let httpClient: API.HTTPClient
        public init(httpClient: API.HTTPClient) {
            self.httpClient = httpClient
        }

        public func me() async -> Types.UserProfile? {
            do {
                let parameters: [String: Any] = [
                    "dynpage": 1 as Any,
                ]
                let result = try await httpClient.requestHTML(url: httpClient.appendURL("/users/profile"), parameters: parameters)
                let doc = try SwiftSoup.parseBodyFragment(result, httpClient.baseURL)
                guard let avatarElement = try doc.select(".card-image img").first(),
                      let userAuth = AuthManager.shared.getUser()
                else {
                    return nil
                }

                let src = try avatarElement.attr("src")
                guard let avatarSrc = URL(string: src) else { return nil }

                return .init(id: userAuth.id, username: userAuth.username, avatarSrc: avatarSrc)
            } catch {
                return nil
            }
        }
    }
}

public extension Anime365Scraper.Types {
    struct UserProfile {
        let id: Int
        let username: String
        let avatarSrc: URL
    }
}
