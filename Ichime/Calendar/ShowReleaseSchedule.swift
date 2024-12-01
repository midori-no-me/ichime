//
//  ShowReleaseSchedule.swift
//  Ichime
//
//  Created by Flaks Petr on 24.11.2024.
//

import Foundation
import ShikimoriApiClient

struct ShowReleaseSchedule {
  private var shikimoriApiClient: ShikimoriApiClient = ApplicationDependency.container.resolve()
  private var shikimoriBaseUrl: URL = ServiceLocator.shikimoriBaseUrl

  func getSchedule() async throws -> [GroupedShowsFromCalendar] {
    let calendarEntries = try await shikimoriApiClient.getCalendar()
    let showsFromCalendar = calendarEntries.map {
      ShowFromCalendar.createFromShikimoriApi(
        shikimoriBaseUrl: shikimoriBaseUrl,
        calendarEntry: $0
      )
    }

    var showsGroupedByDate: [Date: [ShowFromCalendar]] = [:]

    for showFromCalendar in showsFromCalendar {
      showsGroupedByDate[
        Calendar.current.startOfDay(for: showFromCalendar.nextEpisodeReleaseDate),
        default: []
      ]
      .append(showFromCalendar)
    }

    var items: [GroupedShowsFromCalendar] = []

    for (date, showsFromCalendar) in showsGroupedByDate {
      items.append(
        .init(
          date: date,
          shows: showsFromCalendar.sorted(by: {
            $0.nextEpisodeReleaseDate < $1.nextEpisodeReleaseDate
          })
        )
      )
    }

    return items.sorted(by: {
      $0.date < $1.date
    })
  }
}
