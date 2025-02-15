import Foundation

public struct AnimeV1: Decodable {
  public struct Studio: Decodable {
    public let id: Int
    public let name: String
    public let image: String?
  }

  public let id: Int
  public let name: String
  public let russian: String
  public let image: ImageVariants
  public let score: String
  public let studios: [Studio]
  public let next_episode_at: Date?
}
