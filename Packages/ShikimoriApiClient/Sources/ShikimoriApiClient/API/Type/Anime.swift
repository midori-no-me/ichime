import Foundation

public struct Anime: Sendable, Decodable {
  public let studios: [Studio]
  public let next_episode_at: Date?
  public let rating: String?
}
