import Foundation
import JikanApiClient
import OrderedCollections
import ShikimoriApiClient

struct ShowReleaseSchedule {
  private let shikimoriApiClient: ShikimoriApiClient.ApiClient
  private let jikanApiClient: JikanApiClient.ApiClient

  init(
    shikimoriApiClient: ShikimoriApiClient.ApiClient,
    jikanApiClient: JikanApiClient.ApiClient
  ) {
    self.shikimoriApiClient = shikimoriApiClient
    self.jikanApiClient = jikanApiClient
  }

  func getSchedule() async -> OrderedSet<ShowsFromCalendarGroupedByDate> {
    var showsWithDates = (try? await self.getScheduleFromShikimori()) ?? []

    if showsWithDates.isEmpty {
      showsWithDates = await self.getShowsFromJikan()
    }

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
    var items: Set<ShowFromCalendarWithExactReleaseDate> = []

    let shikimoriCalendarEntries = try await shikimoriApiClient.getCalendar()

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

  private func getShowsFromJikan() async -> Set<ShowFromCalendarWithExactReleaseDate> {
    var jikanAnimes: [JikanApiClient.Anime] = []

    var page = 1

    while true {
      guard let (jikanAnimesFromPage, hasMore) = try? await jikanApiClient.getSchedules(page: page) else {
        break
      }

      if jikanAnimesFromPage.isEmpty {
        break
      }

      jikanAnimes += jikanAnimesFromPage
      page += 1

      if !hasMore {
        break
      }

      // Jikan разрешает только 3 запроса в секунду, но их рейт-лимитер более агрессивный, поэтому делаем не более двух в секунду
      try? await Task.sleep(for: .milliseconds(500))
    }

    var items: Set<ShowFromCalendarWithExactReleaseDate> = []

    for jikanAnime in jikanAnimes {
      guard let item = ShowFromCalendarWithExactReleaseDate(fromJikanAnime: jikanAnime) else {
        continue
      }

      items.insert(item)
    }

    return items
  }
}
