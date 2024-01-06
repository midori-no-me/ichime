//
//  Anime365ScraperManager.swift
//  ani365
//
//  Created by Nikita Nafranets on 14.01.2024.
//

import Combine
import Foundation
import ScraperAPI
import SwiftUI

class ScraperClient: ObservableObject {
    var user: CurrentValueSubject<ScraperAPI.Types.User?, Never> = .init(nil)
    var inited: CurrentValueSubject<Bool, Never> = .init(false)
    var api: ScraperAPI.APIClient

    init(scraperClient: ScraperAPI.APIClient) {
        api = scraperClient
        Task {
            await checkUser()
            await MainActor.run {
                self.inited.send(true)
            }
        }
    }

    func checkUser() async {
        do {
            let user = try await api.sendAPIRequest(ScraperAPI.Request.GetMe())
            await MainActor.run {
                self.user.send(user)
            }
        } catch {}
    }

    func startAuth(username: String, password: String) async throws -> ScraperAPI.Types.User {
        let user = try await api.sendAPIRequest(ScraperAPI.Request.Login(username: username, password: password))
        await MainActor.run {
            self.user.send(user)
        }
        return user
    }

    func dropAuth() {
        api.session.logout()
        user.send(nil)
    }
}
