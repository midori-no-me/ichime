import Foundation

public struct CalendarEntry: Sendable, Decodable {
  public struct Anime: Sendable, Decodable {
    public let id: Int
    public let name: String
    public let russian: String
    public let image: ImageVariants
  }

  public let next_episode: Int
  public let next_episode_at: Date
  public let anime: Anime
}
