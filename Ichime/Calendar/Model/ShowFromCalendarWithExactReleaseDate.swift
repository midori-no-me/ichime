import Foundation
import ShikimoriApiClient

struct ShowFromCalendarWithExactReleaseDate: Hashable, Identifiable {
  let id: Int
  let title: ShowName
  let posterUrl: URL?
  let nextEpisodeNumber: Int?
  let nextEpisodeReleaseDate: Date

  init(
    fromShikimoriCalendarEntry: ShikimoriApiClient.CalendarEntry,
    shikimoriBaseUrl: URL
  ) {
    let anime = fromShikimoriCalendarEntry.anime

    self.id = anime.id
    self.title = .parsed(anime.name, anime.russian.isEmpty ? nil : anime.russian)
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
