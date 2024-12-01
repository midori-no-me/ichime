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
final class ShowListStatus {
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
