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
    
    private let authViewManager: Anime365ScraperAuthViewManager
    private var cancellable: AnyCancellable?
    init(authViewManager: Anime365ScraperAuthViewManager) {
        self.authViewManager = authViewManager
        user = Anime365Scraper.AuthManager.shared.getUser()
    }
    
    enum AuthError: Error {
        case invalidCredentials
        case networkError
    }
    
    func startAuth() async throws -> Anime365Scraper.AuthManager.Types.UserAuth {
        authViewManager.isNeedAuth = true
        
        let user = try await withCheckedThrowingContinuation { continuation in
            self.cancellable = authViewManager.$isNeedAuth
                .dropFirst()
                .sink { isNeedAuth in
                    if !isNeedAuth {
                        let user = Anime365Scraper.AuthManager.shared.getUser()
                        continuation.resume(returning: user)
                    }
                }
        }
        
        guard let user else {
            throw AuthError.invalidCredentials
        }
        cancellable?.cancel()
        return user
    }
}

class Anime365ScraperAuthViewManager: ObservableObject {
    @Published var isNeedAuth = false
}
