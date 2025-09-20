import Anime365Kit
import Foundation

enum AuthenticationError: Error {
  case invalidCredentials
  case unknown
}

struct AuthenticationManager {
  private let anime365KitFactory: Anime365KitFactory
  private let currentUserInfo: CurrentUserInfo
  private let animeListEntriesCount: AnimeListEntriesCount
  private let urlSession: URLSession

  init(
    anime365KitFactory: Anime365KitFactory,
    currentUserInfo: CurrentUserInfo,
    animeListEntriesCount: AnimeListEntriesCount,
    urlSession: URLSession
  ) {
    self.anime365KitFactory = anime365KitFactory
    self.currentUserInfo = currentUserInfo
    self.animeListEntriesCount = animeListEntriesCount
    self.urlSession = urlSession
  }

  func authenticate(
    email: String,
    password: String
  ) async throws(AuthenticationError) -> Void {
    do {
      try await self.anime365KitFactory
        .createWebClient()
        .login(username: email, password: password)
    }
    catch {
      switch error {
      case .invalidCredentials:
        throw .invalidCredentials
      default:
        throw .unknown
      }
    }

    let profile = try? await self.anime365KitFactory
      .createWebClient()
      .getProfile()

    guard let profile else {
      throw .unknown
    }

    self.currentUserInfo.save(
      id: profile.id,
      name: profile.name,
      avatarURLPath: profile.avatarURL.path()
    )
  }

  func logout() async -> Void {
    self.currentUserInfo.clear()
    self.animeListEntriesCount.clear()

    let cookieStorage = self.urlSession.configuration.httpCookieStorage
    for cookie in cookieStorage?.cookies ?? [] {
      cookieStorage?.deleteCookie(cookie)
    }
  }
}
