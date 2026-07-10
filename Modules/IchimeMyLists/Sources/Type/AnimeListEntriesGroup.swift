import Foundation
import OrderedCollections

public struct AnimeListEntriesGroup: Identifiable {
  public let letter: String
  public let entries: OrderedSet<AnimeListEntry>

  public var id: String {
    self.letter
  }
}
