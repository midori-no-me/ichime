//
//  Anime365ScraperManager.swift
//  ani365
//
//  Created by Nikita Nafranets on 14.01.2024.
//

import Anime365Scraper
import Combine
import Foundation

@MainActor
class Anime365ScraperManager: ObservableObject {
    @Published var user: Anime365Scraper.AuthManager.Types.UserAuth?

    init() {
        user = Anime365Scraper.AuthManager.shared.getUser()
    }

    func startAuth(username: String, password: String) async throws -> Anime365Scraper.AuthManager.Types.UserAuth {
        let user = try await Anime365Scraper.AuthManager.shared.login(username: username, password: password)
        self.user = user
        return user
    }

    func dropAuth() {
        Anime365Scraper.AuthManager.shared.logout()
        user = nil
    }
}
