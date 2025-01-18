import Anime365ApiClient
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

  enum BroadcastType {
    case tv
    case other

    static func createFromApiType(apiType: String) -> Self {
      switch apiType {
      case "tv":
        return .tv
      default:
        return .other
      }
    }
  }

  let id: Int
  let title: Title
  let posterUrl: URL?
  let score: Float?
  let numberOfEpisodes: Int?
  let broadcastType: BroadcastType
  let isOngoing: Bool
  let nextEpisodeNumber: Int
  let nextEpisodeReleaseDate: Date

  static func createFromShikimoriApi(
    shikimoriBaseUrl: URL,
    calendarEntry: CalendarEntry
  ) -> ShowFromCalendar {
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
      score: score <= 0 ? nil : Float(anime.score),
      numberOfEpisodes: anime.episodes <= 0 ? nil : anime.episodes,
      broadcastType: .createFromApiType(apiType: anime.kind),
      isOngoing: anime.status == "ongoing",
      nextEpisodeNumber: calendarEntry.next_episode,
      nextEpisodeReleaseDate: isoDateFormatter.date(from: calendarEntry.next_episode_at)!
    )
  }

  static func == (lhs: ShowFromCalendar, rhs: ShowFromCalendar) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
  }
}
