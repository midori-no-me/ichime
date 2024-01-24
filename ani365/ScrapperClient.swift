//
//  Anime365ScraperManager.swift
//  ani365
//
//  Created by Nikita Nafranets on 14.01.2024.
//

import Combine
import Foundation
import ScraperAPI

@MainActor
class ScrapperClient: ObservableObject {
    @Published var user: ScraperAPI.Types.User?
    private let scraperClient: ScraperAPI.APIClient

    init(scraperClient: ScraperAPI.APIClient) {
        self.scraperClient = scraperClient
        self.user = UserManager.loadUserAuth()
    }

    func startAuth(username: String, password: String) async throws -> ScraperAPI.Types.User {
        let user = try await scraperClient.sendAPIRequest(ScraperAPI.Request.Login(username: username, password: password))
        self.user = user
        UserManager.saveUserAuth(user)
        return user
    }

    func dropAuth() {
        scraperClient.session.logout()
        UserManager.dropUserAuth()
        user = nil
    }
}

enum UserManager {
    // Сохранение UserAuth в UserDefaults
    static func saveUserAuth(_ userAuth: ScraperAPI.Types.User) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(userAuth)
            UserDefaults.standard.set(data, forKey: "userAuth")
        } catch {
            print("Failed to save UserAuth: \(error)")
        }
    }

    static func dropUserAuth() {
        UserDefaults.standard.removeObject(forKey: "userAuth")
    }

    // Загрузка UserAuth из UserDefaults
    static func loadUserAuth() -> ScraperAPI.Types.User? {
        guard let data = UserDefaults.standard.data(forKey: "userAuth") else { return nil }

        do {
            let decoder = JSONDecoder()
            let userAuth = try decoder.decode(ScraperAPI.Types.User.self, from: data)
            return userAuth
        } catch {
            print("Failed to load UserAuth: \(error)")
            return nil
        }
    }
}
