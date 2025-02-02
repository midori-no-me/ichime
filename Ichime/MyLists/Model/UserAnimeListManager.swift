import Foundation
import SwiftData

@ModelActor
actor UserAnimeListManager {
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

  func getAllCount() -> Int {
    do {
      let descriptor = FetchDescriptor<UserAnimeListModel>()
      return try modelExecutor.modelContext.fetchCount(descriptor)
    }
    catch {
      return 0
    }
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
