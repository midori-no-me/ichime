import Foundation
import IchimeShow
import ShikimoriApiClient

public struct ShowFromCalendarWithExactReleaseDate: Hashable, Identifiable {
  // MARK: Properties

  public let id: Int
  public let title: ShowName
  public let posterURL: URL?
  public let nextEpisodeNumber: Int?
  public let nextEpisodeReleaseDate: Date

  // MARK: Lifecycle

  public init(
    fromShikimoriCalendarEntry: ShikimoriApiClient.CalendarEntry,
    shikimoriBaseURL: URL
  ) {
    let anime = fromShikimoriCalendarEntry.anime

    self.id = anime.id
    self.title = .parsed(anime.name, anime.russian.isEmpty ? nil : anime.russian)
    self.posterURL = URL(string: shikimoriBaseURL.absoluteString + anime.image.original)
    self.nextEpisodeNumber = fromShikimoriCalendarEntry.next_episode
    self.nextEpisodeReleaseDate = fromShikimoriCalendarEntry.next_episode_at
  }

  // MARK: Static Functions

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  // MARK: Functions

  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
  }
}
