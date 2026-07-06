import Foundation
import OrderedCollections
import ShikimoriApiClient

struct ShowReleaseSchedule: Sendable {
  private let shikimoriApiClient: ShikimoriApiClient.ApiClient
  private let anime365BaseURL: Anime365BaseURL

  init(
    shikimoriApiClient: ShikimoriApiClient.ApiClient,
    anime365BaseURL: Anime365BaseURL
  ) {
    self.shikimoriApiClient = shikimoriApiClient
    self.anime365BaseURL = anime365BaseURL
  }

  func getSchedule() async -> OrderedSet<ShowsFromCalendarGroupedByDate> {
    let showsWithDates = (try? await self.getScheduleFromShikimori()) ?? []

    var showsGroupedByDate: [Date: [ShowFromCalendarWithExactReleaseDate]] = [:]

    for showsWithDate in showsWithDates {
      showsGroupedByDate[
        Calendar.current.startOfDay(for: showsWithDate.nextEpisodeReleaseDate),
        default: []
      ]
      .append(showsWithDate)
    }

    var items: [ShowsFromCalendarGroupedByDate] = []

    for (date, showsFromCalendar) in showsGroupedByDate {
      items.append(
        .init(
          date: date,
          shows: .init(
            showsFromCalendar.sorted(by: {
              $0.nextEpisodeReleaseDate < $1.nextEpisodeReleaseDate
            })
          )
        )
      )
    }

    return .init(
      items.sorted(by: {
        $0.date < $1.date
      })
    )
  }

  private func getScheduleFromShikimori() async throws -> Set<ShowFromCalendarWithExactReleaseDate> {
    var items = Set<ShowFromCalendarWithExactReleaseDate>()

    let shikimoriCalendarEntries = try await shikimoriApiClient.getCalendar(
      censored: !Anime365BaseURL.isAdultDomain(self.anime365BaseURL.get()),
    )

    for shikimoriCalendarEntry in shikimoriCalendarEntries {
      let item = ShowFromCalendarWithExactReleaseDate(
        fromShikimoriCalendarEntry: shikimoriCalendarEntry,
        shikimoriBaseUrl: self.shikimoriApiClient.baseUrl
      )

      // Не показываем серии, которые должны были выйти более 5 часов назад
      if Date.now.addingTimeInterval(60 * 60 * 5 * -1) >= item.nextEpisodeReleaseDate {
        continue
      }

      items.insert(item)
    }

    return items
  }
}
