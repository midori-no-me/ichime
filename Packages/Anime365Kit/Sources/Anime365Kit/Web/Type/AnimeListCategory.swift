public enum AnimeListCategory: Sendable {
  case watching
  case completed
  case onHold
  case dropped
  case planned

  public var webPath: String {
    switch self {
    case .watching:
      "watching"
    case .completed:
      "completed"
    case .onHold:
      "onhold"
    case .dropped:
      "dropped"
    case .planned:
      "planned"
    }
  }

  public var numericID: Int {
    switch self {
    case .planned:
      0
    case .watching:
      1
    case .completed:
      2
    case .onHold:
      3
    case .dropped:
      4
    }
  }
}
