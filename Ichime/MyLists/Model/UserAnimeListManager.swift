import Foundation
import ScraperAPI
import SwiftData

@ModelActor
actor UserAnimeListManager {
  func getById(id: Int) -> UserAnimeListModel? {
    do {
      let descriptor =
        FetchDescriptor<UserAnimeListModel>(predicate: #Predicate<UserAnimeListModel> { $0.id == id })
      let result = try modelExecutor.modelContext.fetch(descriptor)
      return result.first
    }
    catch {
      return nil
    }
  }

  func updateStatusById(id: Int, status: AnimeWatchStatus) {
    do {
      let descriptor =
        FetchDescriptor<UserAnimeListModel>(predicate: #Predicate<UserAnimeListModel> { $0.id == id })
      let result = try modelExecutor.modelContext.fetch(descriptor)
      guard let item = result.first else { return }
      item.statusRaw = status.rawValue
      try modelExecutor.modelContext.save()
    }
    catch {
      return
    }
  }

  func getByStatus(status: AnimeWatchStatus) -> [UserAnimeListModel] {
    do {
      let descriptor =
        FetchDescriptor<UserAnimeListModel>(predicate: #Predicate<UserAnimeListModel> { $0.status == status })
      return try modelExecutor.modelContext.fetch(descriptor)
    }
    catch {
      return []
    }
  }

  func getAll() -> [UserAnimeListModel] {
    do {
      let descriptor = FetchDescriptor<UserAnimeListModel>()
      return try modelExecutor.modelContext.fetch(descriptor)
    }
    catch {
      return []
    }
  }

  func getAllCount() -> Int {
    do {
      let descriptor = FetchDescriptor<UserAnimeListModel>()
      return try modelExecutor.modelContext.fetchCount(descriptor)
    }
    catch {
      return 0
    }
  }

  func insert(id: Int, name: UserAnimeListName, status: AnimeWatchStatus, score: Int, progress: UserAnimeProgress) {
    let status = UserAnimeListModel(id: id, name: name, status: status, score: score, progress: progress)
    modelExecutor.modelContext.insert(status)
    try? modelExecutor.modelContext.save()
  }

  func insertMany(
    listShows: [(id: Int, name: UserAnimeListName, status: AnimeWatchStatus, score: Int, progress: UserAnimeProgress)]
  ) {
    for show in listShows {
      let status = UserAnimeListModel(
        id: show.id,
        name: show.name,
        status: show.status,
        score: show.score,
        progress: show.progress
      )
      modelExecutor.modelContext.insert(status)
    }
    try? modelExecutor.modelContext.save()
  }

  func remove(id: Int) {
    let descriptor = FetchDescriptor<UserAnimeListModel>(predicate: #Predicate<UserAnimeListModel> { $0.id == id })
    guard let status = try? modelExecutor.modelContext.fetch(descriptor).first else { return }
    modelExecutor.modelContext.delete(status)
    try? modelExecutor.modelContext.save()
  }
}
