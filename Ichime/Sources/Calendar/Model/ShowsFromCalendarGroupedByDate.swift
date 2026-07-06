import Foundation
import OrderedCollections

struct ShowsFromCalendarGroupedByDate: Identifiable, Hashable {
  let date: Date
  let shows: OrderedSet<ShowFromCalendarWithExactReleaseDate>

  var id: Date {
    self.date
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(self.date)
  }
}
