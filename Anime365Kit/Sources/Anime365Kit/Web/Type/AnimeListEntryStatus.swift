public enum AnimeListEntryStatus {
  case watching
  case completed
  case onHold
  case dropped
  case planned
  case notInList

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
    case .notInList:
      99
    }
  }

  public static func create(fromNumericID: Int) -> Self? {
    switch fromNumericID {
    case 0:
      .planned
    case 1:
      .watching
    case 2:
      .completed
    case 3:
      .onHold
    case 4:
      .dropped
    case 99:
      .notInList
    default:
      nil
    }
  }
}
