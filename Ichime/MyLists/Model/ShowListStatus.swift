import Foundation
import ScraperAPI
import SwiftData

protocol ShowStatusProtocol {
  var key: String { get }
}

extension ScraperAPI.Types.ListCategoryType: ShowStatusProtocol {
  public var key: String {
    switch self {
    case .planned: return "planned"
    case .watching: return "watching"
    case .completed: return "completed"
    case .onHold: return "onHold"
    case .dropped: return "dropped"
    }
  }
}

enum CategoryType: Int, Codable, CaseIterable, ShowStatusProtocol {
  case watching = 0
  case completed = 1
  case onHold = 2
  case dropped = 3
  case planned = 4

  var key: String {
    switch self {
    case .watching: return "watching"
    case .completed: return "completed"
    case .onHold: return "onHold"
    case .dropped: return "dropped"
    case .planned: return "planned"
    }
  }
}

@Model
final class ShowListStatusEntity {
  @Attribute(.unique) var id: Int
  @Attribute var statusRaw: String  // Используем String для универсального хранения

  // Свойство для работы с `CategoryType`
  var status: CategoryType {
    switch statusRaw {
    case "watching": return .watching
    case "completed": return .completed
    case "onHold": return .onHold
    case "dropped": return .dropped
    case "planned": return .planned
    default: return .watching
    }
  }

  init(id: Int, status: ShowStatusProtocol) {
    self.id = id
    statusRaw = status.key
  }
}

@Observable
class ShowListStatusModel {
  private let apiClient: ScraperAPI.APIClient
  private let userManager: UserManager
  private let modelContainer: ModelContainer

  init(
    apiClient: ScraperAPI.APIClient,
    userManager: UserManager,
    modelContainer: ModelContainer
  ) {
    self.apiClient = apiClient
    self.userManager = userManager
    self.modelContainer = modelContainer
  }

  @MainActor func getById(id: Int) -> ShowListStatusEntity? {
    do {
      let descriptor =
        FetchDescriptor<ShowListStatusEntity>(predicate: #Predicate<ShowListStatusEntity> { $0.id == id })
      let result = try modelContainer.mainContext.fetch(descriptor)
      return result.first
    }
    catch {
      return nil
    }
  }

  @MainActor
  func saveData(listShows: [ShowListStatusEntity]) {
    for show in listShows {
      let status = ShowListStatusEntity(id: show.id, status: show.status)
      modelContainer.mainContext.insert(status)
    }
    try? modelContainer.mainContext.save()
    print("saved list statuses")
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

    var shows: [ShowListStatusEntity] = []

    // Сохраняем все шоу в SwiftData
    for category in categories {
      for show in category.shows {
        let status = ShowListStatusEntity(id: show.id, status: category.type)
        shows.append(status)
      }
    }

    await saveData(listShows: shows)
  }
}
