import Foundation
import OrderedCollections

struct AnimeListEntriesGroup: Identifiable {
  let letter: String
  let entries: OrderedSet<AnimeListEntry>

  var id: String {
    self.letter
  }
}
