public enum AnimeListEntryStatus: Sendable {
  case watching
  case completed
  case onHold
  case dropped
  case planned
  case notInList

  // MARK: Static Functions

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
