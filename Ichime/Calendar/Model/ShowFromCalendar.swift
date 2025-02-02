import Foundation
import ShikimoriApiClient

struct ShowFromCalendar: Hashable, Identifiable {
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
  let nextEpisodeNumber: Int
  let nextEpisodeReleaseDate: Date

  static func createFromShikimoriApi(
    shikimoriBaseUrl: URL,
    calendarEntry: CalendarEntry
  ) -> Self {
    let anime = calendarEntry.anime

    let score = Float(anime.score) ?? 0

    let isoDateFormatter = ISO8601DateFormatter()
    isoDateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    print(calendarEntry.next_episode_at)

    return .init(
      id: anime.id,
      title: .init(
        translated: .init(
          russian: anime.russian.isEmpty ? nil : anime.russian,
          japaneseRomaji: anime.name
        )
      ),
      posterUrl: URL(string: shikimoriBaseUrl.absoluteString + anime.image.original),
      nextEpisodeNumber: calendarEntry.next_episode,
      nextEpisodeReleaseDate: isoDateFormatter.date(from: calendarEntry.next_episode_at)!
    )
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
  }
}
