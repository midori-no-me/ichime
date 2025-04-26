import Foundation
import OrderedCollections

struct ShowsFromCalendarGroupedByDate: Hashable {
  let date: Date
  let shows: OrderedSet<ShowFromCalendarWithExactReleaseDate>

  func hash(into hasher: inout Hasher) {
    hasher.combine(self.date)
  }
}
