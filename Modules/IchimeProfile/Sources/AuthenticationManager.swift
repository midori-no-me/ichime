import Anime365Kit
import Foundation
import IchimeAnime365
import IchimeMyLists

public enum AuthenticationError: Error {
  case invalidCredentials
  case unknown
}

public actor AuthenticationManager {
  // MARK: Properties

  private let anime365KitFactory: Anime365KitFactory
  private let animeListEntriesCount: AnimeListEntriesCount
  private let profilePageService: ProfilePageService
  private let urlSession: URLSession

  // MARK: Lifecycle

  public init(
    anime365KitFactory: Anime365KitFactory,
    animeListEntriesCount: AnimeListEntriesCount,
    profilePageService: ProfilePageService,
    urlSession: URLSession
  ) {
    self.anime365KitFactory = anime365KitFactory
    self.animeListEntriesCount = animeListEntriesCount
    self.profilePageService = profilePageService
    self.urlSession = urlSession
  }

  // MARK: Static Functions

  private static func createUser(from profile: Profile) -> User {
    .init(
      id: profile.id,
      name: profile.name,
      avatar: profile.avatarURL
    )
  }

  // MARK: Functions

  @MainActor
  public func fetchCurrentUser(
    currentUserStore: CurrentUserStore,
    baseURL: URL,
  ) async throws -> Void {
    let profile: Profile

    do {
      profile = try await self.profilePageService.getProfile(baseURL: baseURL)
    }
    catch {
      if case Anime365Kit.WebClientError.authenticationRequired = error {
        currentUserStore.setUser(user: nil)

        return
      }

      throw error
    }

    currentUserStore.setUser(user: Self.createUser(from: profile))
  }

  @MainActor
  public func authenticate(
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

    await self.profilePageService.invalidate()

    let profile = try? await self.profilePageService.getProfile(baseURL: baseURL)

    guard let profile else {
      throw .unknown
    }

    currentUserStore.setUser(user: Self.createUser(from: profile))
  }

  @MainActor
  public func logout(currentUserStore: CurrentUserStore) async -> Void {
    await self.animeListEntriesCount.clear()
    await self.profilePageService.invalidate()

    let cookieStorage = self.urlSession.configuration.httpCookieStorage
    for cookie in cookieStorage?.cookies ?? [] {
      cookieStorage?.deleteCookie(cookie)
    }

    currentUserStore.setUser(user: nil)
  }
}
