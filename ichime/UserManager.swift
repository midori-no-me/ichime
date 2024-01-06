//
//  Anime365ScraperManager.swift
//  ichime
//
//  Created by Nikita Nafranets on 14.01.2024.
//

import Foundation
import ScraperAPI
import SwiftUI

@Observable
class UserManager {
    enum State {
        case idle
        case loading
        case isAuth(ScraperAPI.Types.User)
        case isAnonym
    }

    var state: State = .idle
    var subscribed: Bool = false

    private let api: ScraperAPI.APIClient

    init(client: ScraperAPI.APIClient) {
        api = client
    }

    func checkAuth() async {
        do {
            await loading()
            let user = try await api.sendAPIRequest(ScraperAPI.Request.GetMe())
            print("success check auth")
            await saveUser(user: user)
        } catch {
            print(error.localizedDescription)
            await isAnonym()
        }
    }

    func startAuth(username: String, password: String) async throws -> ScraperAPI.Types.User {
        await loading()
        let user = try await api.sendAPIRequest(ScraperAPI.Request.Login(username: username, password: password))
        print("success auth")
        await saveUser(user: user)
        return user
    }

    func dropAuth() {
        api.session.logout()
        state = .isAnonym
    }

    @MainActor
    private func loading() {
        state = .loading
        print("start loading")
    }

    @MainActor
    private func isAnonym() {
        state = .isAnonym
        print("auth is fail")
    }

    @MainActor
    private func saveUser(user: ScraperAPI.Types.User) {
        state = .isAuth(user)
        subscribed = user.subscribed
        print("save user to auth")
    }
}
