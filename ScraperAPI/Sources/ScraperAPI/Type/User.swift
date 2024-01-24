//
//  User.swift
//
//
//  Created by Nikita Nafranets on 24.01.2024.
//

import Foundation
import SwiftSoup

public extension ScraperAPI.Types {
    struct User: Codable {
        public let id: Int
        public let username: String
        public let avatarURL: URL

        init(id: Int, username: String, avatarURL: URL) {
            self.id = id
            self.username = username
            self.avatarURL = avatarURL
        }

        init(from element: Element, baseURL: URL) throws {
            guard let idString = try? element.text().firstMatch(of: #/ID аккаунта: (\d+)/#)?.output.1,
                  let id = Int(idString),
                  let avatarSrc = try? element.select(".card-image.hide-on-small-and-down img").first()?.attr("src"),
                  let username = try? element.select(".m-small-title").first()?.text()
            else {
                throw ScraperAPI.APIClientError.parseError
            }

            let avatarURL = baseURL.appending(path: avatarSrc.dropFirst())
            self.init(id: id, username: username, avatarURL: avatarURL)
        }
    }
}
