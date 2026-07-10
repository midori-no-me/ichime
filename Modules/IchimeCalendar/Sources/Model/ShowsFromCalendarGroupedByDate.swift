import Foundation
import OrderedCollections

public struct ShowsFromCalendarGroupedByDate: Identifiable, Hashable {
  // MARK: Properties

  public let date: Date
  public let shows: OrderedSet<ShowFromCalendarWithExactReleaseDate>

  // MARK: Computed Properties

  public var id: Date {
    self.date
  }

  // MARK: Functions

  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.date)
  }
}
