import Foundation

public struct Anime: Decodable {
  public struct Studio: Decodable {
    public let id: Int
    public let name: String
    public let image: String?
  }

  public let studios: [Studio]
  public let next_episode_at: Date?
}
