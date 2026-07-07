import Foundation
import IchimeShow
import ShikimoriApiClient

public struct ShowFromCalendarWithExactReleaseDate: Hashable, Identifiable {
  public let id: Int
  public let title: ShowName
  public let posterUrl: URL?
  public let nextEpisodeNumber: Int?
  public let nextEpisodeReleaseDate: Date

  public init(
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

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
  }
}
