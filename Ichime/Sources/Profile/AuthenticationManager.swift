import Anime365Kit
import Foundation

enum AuthenticationError: Error {
  case invalidCredentials
  case unknown
}

actor AuthenticationManager {
  private let anime365KitFactory: Anime365KitFactory
  private let animeListEntriesCount: AnimeListEntriesCount
  private let urlSession: URLSession

  init(
    anime365KitFactory: Anime365KitFactory,
    animeListEntriesCount: AnimeListEntriesCount,
    urlSession: URLSession
  ) {
    self.anime365KitFactory = anime365KitFactory
    self.animeListEntriesCount = animeListEntriesCount
    self.urlSession = urlSession
  }

  @MainActor
  func fetchCurrentUser(
    currentUserStore: CurrentUserStore,
    baseURL: URL,
  ) async throws -> Void {
    let anime365WebClient = await self.anime365KitFactory
      .createWebClient(withBaseURL: baseURL)

    let profile: Profile

    do {
      profile = try await anime365WebClient.getProfile()
    }
    catch {
      if case Anime365Kit.WebClientError.authenticationRequired = error {
        currentUserStore.setUser(user: nil)

        return
      }

      throw error
    }

    currentUserStore.setUser(user: .init(id: profile.id, name: profile.name, avatar: profile.avatarURL))
  }

  @MainActor
  func authenticate(
    currentUserStore: CurrentUserStore,
    baseURL: URL,
    email: String,
    password: String
  ) async throws(AuthenticationError) -> Void {
    let anime365WebClient = await self.anime365KitFactory
      .createWebClient(withBaseURL: baseURL)

    do {
      try await anime365WebClient.login(username: email, password: password)
    }
    catch {
      switch error {
      case .invalidCredentials:
        throw .invalidCredentials
      default:
        throw .unknown
      }
    }

    let profile = try? await anime365WebClient.getProfile()

    guard let profile else {
      throw .unknown
    }

    currentUserStore.setUser(user: .init(id: profile.id, name: profile.name, avatar: profile.avatarURL))
  }

  @MainActor
  func logout(currentUserStore: CurrentUserStore) async -> Void {
    await self.animeListEntriesCount.clear()

    let cookieStorage = self.urlSession.configuration.httpCookieStorage
    for cookie in cookieStorage?.cookies ?? [] {
      cookieStorage?.deleteCookie(cookie)
    }

    currentUserStore.setUser(user: nil)
  }
}
