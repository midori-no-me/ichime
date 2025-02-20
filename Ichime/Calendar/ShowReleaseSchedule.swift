import Foundation
import ShikimoriApiClient

struct ShowReleaseSchedule {
  private let shikimoriApiClient: ShikimoriApiClient.ApiClient

  init(
    shikimoriApiClient: ShikimoriApiClient.ApiClient
  ) {
    self.shikimoriApiClient = shikimoriApiClient
  }

  func getSchedule() async throws -> [GroupedShowsFromCalendar] {
    let calendarEntries = try await shikimoriApiClient.getCalendar()
    let showsFromCalendar = calendarEntries.map {
      ShowFromCalendar.createFromShikimoriApi(
        shikimoriBaseUrl: self.shikimoriApiClient.baseUrl,
        calendarEntry: $0
      )
    }
    // Не показываем серии, которые должны были выйти более 5 часов назад
    .filter { Date.now.addingTimeInterval(60 * 60 * 5 * -1) < $0.nextEpisodeReleaseDate }

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
