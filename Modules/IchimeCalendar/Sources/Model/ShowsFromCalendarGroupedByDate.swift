import Foundation
import OrderedCollections

public struct ShowsFromCalendarGroupedByDate: Identifiable, Hashable {
  public let date: Date
  public let shows: OrderedSet<ShowFromCalendarWithExactReleaseDate>

  public var id: Date {
    self.date
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.date)
  }
}
