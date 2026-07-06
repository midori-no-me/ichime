import Anime365Kit

enum AnimeListEntryStatus: CaseIterable {
  case watching
  case completed
  case onHold
  case dropped
  case planned
  case notInList

  var category: AnimeListCategory? {
    switch self {
    case .watching:
      .watching
    case .completed:
      .completed
    case .onHold:
      .onHold
    case .dropped:
      .dropped
    case .planned:
      .planned
    case .notInList:
      nil
    }
  }

  init(fromAnime365KitType type: Anime365Kit.AnimeListEntryStatus) {
    switch type {
    case .watching:
      self = .watching
    case .completed:
      self = .completed
    case .onHold:
      self = .onHold
    case .dropped:
      self = .dropped
    case .planned:
      self = .planned
    case .notInList:
      self = .notInList
    }
  }
}
