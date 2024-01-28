//
//  Anime365ScraperManager.swift
//  ani365
//
//  Created by Nikita Nafranets on 14.01.2024.
//

import Combine
import Foundation
import ScraperAPI

class ScraperClient: ObservableObject {
    @Published var user: ScraperAPI.Types.User?
    @Published var counter = 0
    @Published var api: ScraperAPI.APIClient

    init(scraperClient: ScraperAPI.APIClient) {
        api = scraperClient
        Task {
            await checkUser()
            await checkCounter()
        }
    }

    @MainActor
    func updateUser(_ newUser: ScraperAPI.Types.User) {
        user = newUser
    }

    func checkUser() async {
        do {
            let user = try await api.sendAPIRequest(ScraperAPI.Request.GetMe())
            await MainActor.run {
                self.user = user
            }
        } catch {}
    }

    func checkCounter() async {
        do {
            let counter = try await api.sendAPIRequest(ScraperAPI.Request.GetNotificationCount())
            await MainActor.run {
                self.counter = counter
            }
        } catch {}
    }

    func startAuth(username: String, password: String) async throws -> ScraperAPI.Types.User {
        let user = try await api.sendAPIRequest(ScraperAPI.Request.Login(username: username, password: password))
        await MainActor.run {
            self.user = user
        }
        return user
    }

    func dropAuth() {
        api.session.logout()
        user = nil
    }
}
