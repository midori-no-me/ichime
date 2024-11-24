//
//  ShowsFromCalendarGroupedByDay.swift
//  Ichime
//
//  Created by Flaks Petr on 24.11.2024.
//

import Foundation

struct GroupedShowsFromCalendar: Hashable {
  let date: Date
  let shows: [ShowFromCalendar]

  func hash(into hasher: inout Hasher) {
    hasher.combine(date)
  }
}
