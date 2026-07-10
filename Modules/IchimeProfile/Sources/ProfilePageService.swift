import Anime365Kit
import Foundation
import IchimeAnime365

public actor ProfilePageService {
  // MARK: Properties

  private let anime365KitFactory: Anime365KitFactory

  private var cachedProfilePage: (baseURL: URL, profilePage: ProfilePage)?
  private var profilePageTask: (baseURL: URL, task: Task<ProfilePage, Error>)?

  // MARK: Lifecycle

  public init(anime365KitFactory: Anime365KitFactory) {
    self.anime365KitFactory = anime365KitFactory
  }

  // MARK: Functions

  public func getProfile(baseURL: URL) async throws -> Profile {
    try await self.getProfilePage(baseURL: baseURL).profile
  }

  public func getProfilePlayerChannelSettings() async throws -> ProfilePlayerChannelSettings {
    let baseURL = await self.anime365KitFactory.baseURL()

    guard let playerChannelSettings = try await self.getProfilePage(baseURL: baseURL).playerChannelSettings else {
      throw WebClientError.couldNotParseHtml
    }

    return playerChannelSettings
  }

  public func updateProfilePlayerChannel(_ playerChannel: PlayerChannel) async throws -> Void {
    try await self.anime365KitFactory
      .createWebClient()
      .updateProfilePlayerChannel(playerChannel)

    self.invalidate()
  }

  public func invalidate() -> Void {
    self.cachedProfilePage = nil
  }

  private func getProfilePage(baseURL: URL) async throws -> ProfilePage {
    if let cachedProfilePage, cachedProfilePage.baseURL == baseURL {
      return cachedProfilePage.profilePage
    }

    if let profilePageTask, profilePageTask.baseURL == baseURL {
      return try await profilePageTask.task.value
    }

    let task = Task {
      let webClient = await self.anime365KitFactory.createWebClient(withBaseURL: baseURL)

      return try await webClient.getProfilePage()
    }

    self.profilePageTask = (baseURL: baseURL, task: task)

    do {
      let profilePage = try await task.value

      self.cachedProfilePage = (baseURL: baseURL, profilePage: profilePage)
      self.profilePageTask = nil

      return profilePage
    }
    catch {
      self.profilePageTask = nil

      throw error
    }
  }
}
