import Foundation

struct GroupedShowsFromCalendar: Hashable {
  let date: Date
  let shows: [ShowFromCalendar]

  func hash(into hasher: inout Hasher) {
    hasher.combine(self.date)
  }
}
