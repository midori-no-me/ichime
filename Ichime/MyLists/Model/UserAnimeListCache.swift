//
//  UserAnimeListCache.swift
//  Ichime
//
//  Created by Nafranets Nikita on 15.12.2024.
//
import ScraperAPI
import SwiftData

class UserAnimeListCache {
  private let apiClient: ScraperAPI.APIClient
  private let userManager: UserManager
  private let userAnimeListManager: UserAnimeListManager

  init(
    apiClient: ScraperAPI.APIClient,
    userManager: UserManager,
    modelContainer: ModelContainer
  ) {
    self.apiClient = apiClient
    self.userManager = userManager
    self.userAnimeListManager = .init(modelContainer: modelContainer)
  }

  func isCategoriesEmpty() async -> Bool {
    await self.userAnimeListManager.getAllCount() == 0
  }

  func cacheCategories() async {
    guard case let .isAuth(user) = userManager.state else {
      return
    }

    let categories = try? await apiClient.sendAPIRequest(ScraperAPI.Request.GetWatchList(userId: user.id))

    guard let categories = categories else {
      return
    }

    if categories.isEmpty {
      return
    }

    var shows: [(id: Int, name: UserAnimeListName, status: AnimeWatchStatus, score: Int, progress: UserAnimeProgress)] =
      []

    // Сохраняем все шоу в SwiftData
    for category in categories {
      for show in category.shows {
        shows.append(
          (
            id: show.id,
            name: .init(ru: show.name.ru, romaji: show.name.romaji),
            status: .init(from: category.type),
            score: show.score ?? 0,
            progress: .init(watched: show.episodes.watched, total: show.episodes.total)
          )
        )
      }
    }

    await self.userAnimeListManager.insertMany(listShows: shows)
  }
}
