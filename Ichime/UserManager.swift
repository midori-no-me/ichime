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
    self.api = client
    self.restoreUser()
    Task {
      await self.checkAuth()
    }
  }

  func checkAuth() async {
    do {
      await self.loading()
      let user = try await api.sendAPIRequest(ScraperAPI.Request.GetMe())
      print("success check auth")
      await self.saveUser(user: user)
    }
    catch {
      print(error.localizedDescription)
      await self.isAnonym()
    }
  }

  func startAuth(username: String, password: String) async throws -> ScraperAPI.Types.User {
    let user = try await api.sendAPIRequest(
      ScraperAPI.Request.Login(username: username, password: password)
    )
    print("success auth")
    await self.saveUser(user: user)
    return user
  }

  func dropAuth() {
    self.api.session.logout()
    self.state = .isAnonym
    self.cachedUser = nil
  }

  @MainActor
  private func loading() {
    self.state = .loading
    print("start loading")
  }

  @MainActor
  private func isAnonym() {
    self.state = .isAnonym
    print("auth is fail")
  }

  @MainActor
  private func saveUser(user: ScraperAPI.Types.User) {
    self.state = .isAuth(user)
    self.subscribed = user.subscribed

    let encoder = JSONEncoder()
    if let encoded = try? encoder.encode(user) {
      self.cachedUser = encoded
    }
    print("save user to auth")
  }

  private func restoreUser() {
    let decoder = JSONDecoder()
    if let cachedUser,
      let decodedUser = try? decoder.decode(ScraperAPI.Types.User.self, from: cachedUser)
    {
      self.state = .isAuth(decodedUser)
      self.subscribed = decodedUser.subscribed
    }
  }

  private func syncStorageCookie() {}
}
