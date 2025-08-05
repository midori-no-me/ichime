import Foundation
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

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
  }
}
