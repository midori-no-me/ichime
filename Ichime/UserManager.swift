//
//  Anime365ScraperManager.swift
//  ichime
//
//  Created by Nikita Nafranets on 14.01.2024.
//

import Foundation
import Observation
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

  @ObservationIgnored @AppStorage("userManagerCachedUser") private var cachedUser: Data?
  var state: State = .idle
  var subscribed: Bool = false

  private let api: ScraperAPI.APIClient

  init(client: ScraperAPI.APIClient) {
    api = client
    restoreUser()
    Task {
      await checkAuth()
    }
  }

  func checkAuth() async {
    do {
      await loading()
      let user = try await api.sendAPIRequest(ScraperAPI.Request.GetMe())
      print("success check auth")
      await saveUser(user: user)
    }
    catch {
      print(error.localizedDescription)
      await isAnonym()
    }
  }

  func startAuth(username: String, password: String) async throws -> ScraperAPI.Types.User {
    let user = try await api.sendAPIRequest(
      ScraperAPI.Request.Login(username: username, password: password)
    )
    print("success auth")
    await saveUser(user: user)
    return user
  }

  func dropAuth() {
    api.session.logout()
    state = .isAnonym
    cachedUser = nil
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

    let encoder = JSONEncoder()
    if let encoded = try? encoder.encode(user) {
      cachedUser = encoded
    }
    print("save user to auth")
  }

  private func restoreUser() {
    let decoder = JSONDecoder()
    if let cachedUser,
      let decodedUser = try? decoder.decode(ScraperAPI.Types.User.self, from: cachedUser)
    {
      state = .isAuth(decodedUser)
      subscribed = decodedUser.subscribed
    }
  }

  private func syncStorageCookie() {}
}
