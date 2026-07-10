import Foundation
import OrderedCollections

public struct AnimeListEntriesGroup: Identifiable {
  // MARK: Properties

  public let letter: String
  public let entries: OrderedSet<AnimeListEntry>

  // MARK: Computed Properties

  public var id: String {
    self.letter
  }
}
