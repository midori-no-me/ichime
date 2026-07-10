import Anime365Kit

public enum AnimeListEntryStatus: CaseIterable, Sendable {
  case watching
  case completed
  case onHold
  case dropped
  case planned
  case notInList

  // MARK: Computed Properties

  public var category: AnimeListCategory? {
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

  // MARK: Lifecycle

  public init(fromAnime365KitType type: Anime365Kit.AnimeListEntryStatus) {
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
