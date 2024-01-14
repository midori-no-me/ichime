//
//  File.swift
//
//
//  Created by Nikita Nafranets on 10.01.2024.
//

import Foundation

public extension Anime365Scraper {
    class AuthManager {
        init() {
            self.user = UserManager.loadUserAuth()
        }
        
        public static let shared = AuthManager()
        
        private let cookieName = "aaaa8ed0da05b797653c4bd51877d861"
        
        package func getCookieValue() -> String? {
            if let cookies = HTTPCookieStorage.shared.cookies,
               let targetCookie = cookies.first(where: { $0.name == cookieName })
            {
                return targetCookie.value
            }
            return nil
        }
        
        private func createFullCookie(value: String) -> String {
            return "\(cookieName)=\(value)"
        }
        
        private var user: Types.UserAuth?
        
        package func setUser(id: Int, username: String, cookieValue: String) {
            let user = Types.UserAuth(id: id, username: username, cookie: createFullCookie(value: cookieValue))
            UserManager.saveUserAuth(user);
            self.user = user;
        }
        
        public func getUser() -> Types.UserAuth? {
            user
        }
    }
}

public extension Anime365Scraper.AuthManager {
    enum Types {
        public struct UserAuth: Codable {
            public let id: Int
            public let username: String
            public let cookie: String
        }
    }
}

struct UserManager {
    // Сохранение UserAuth в UserDefaults
    static func saveUserAuth(_ userAuth: Anime365Scraper.AuthManager.Types.UserAuth) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(userAuth)
            UserDefaults.standard.set(data, forKey: "userAuth")
        } catch {
            print("Failed to save UserAuth: \(error)")
        }
    }

    // Загрузка UserAuth из UserDefaults
    static func loadUserAuth() -> Anime365Scraper.AuthManager.Types.UserAuth? {
        guard let data = UserDefaults.standard.data(forKey: "userAuth") else { return nil }

        do {
            let decoder = JSONDecoder()
            let userAuth = try decoder.decode(Anime365Scraper.AuthManager.Types.UserAuth.self, from: data)
            return userAuth
        } catch {
            print("Failed to load UserAuth: \(error)")
            return nil
        }
    }
}
