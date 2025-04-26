import Foundation
import JikanApiClient
import ShikimoriApiClient

struct ShowFromCalendarWithExactReleaseDate: Hashable, Identifiable {
  struct Title {
    struct TranslatedTitles {
      let russian: String?
      let japaneseRomaji: String
    }

    let translated: TranslatedTitles
  }

  let id: Int
  let title: Title
  let posterUrl: URL?
  let nextEpisodeNumber: Int?
  let nextEpisodeReleaseDate: Date

  init(
    fromShikimoriCalendarEntry: ShikimoriApiClient.CalendarEntry,
    shikimoriBaseUrl: URL
  ) {
    let anime = fromShikimoriCalendarEntry.anime

    self.id = anime.id
    self.title = .init(
      translated: .init(
        russian: anime.russian.isEmpty ? nil : anime.russian,
        japaneseRomaji: anime.name
      )
    )
    self.posterUrl = URL(string: shikimoriBaseUrl.absoluteString + anime.image.original)
    self.nextEpisodeNumber = fromShikimoriCalendarEntry.next_episode
    self.nextEpisodeReleaseDate = fromShikimoriCalendarEntry.next_episode_at
  }

  init?(
    fromJikanAnime: JikanApiClient.Anime
  ) {
    self.id = fromJikanAnime.mal_id
    self.title = .init(
      translated: .init(
        russian: nil,
        japaneseRomaji: fromJikanAnime.title
      )
    )
    self.posterUrl = fromJikanAnime.images.jpg.image_url

    guard let dayStringPlural = fromJikanAnime.broadcast.day else {
      return nil
    }

    let pluralDayNameToWeekday: [String: Weekday] = [
      "Mondays": .monday,
      "Tuesdays": .tuesday,
      "Wednesdays": .wednesday,
      "Thursdays": .thursday,
      "Fridays": .friday,
      "Saturdays": .saturday,
      "Sundays": .sunday,
    ]

    guard let weekday = pluralDayNameToWeekday[dayStringPlural] else {
      return nil
    }

    guard let timeString = fromJikanAnime.broadcast.time else {
      return nil
    }

    let hourAndMinute = timeString.components(separatedBy: ":")

    guard let hour = Int(hourAndMinute[0]) else {
      return nil
    }

    guard let minute = Int(hourAndMinute[1]) else {
      return nil
    }

    guard let timezoneIdentifier = fromJikanAnime.broadcast.timezone else {
      return nil
    }

    guard let timezone = TimeZone(identifier: timezoneIdentifier) else {
      return nil
    }

    guard
      let nextClosestDate = getNextClosestDate(
        weekday: weekday,
        time: (hour: hour, minute: minute),
        timezone: timezone
      )
    else {
      return nil
    }

    self.nextEpisodeNumber = nil
    self.nextEpisodeReleaseDate = nextClosestDate
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
  }
}
