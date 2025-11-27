import Foundation

public struct Anime: Sendable, Decodable {
  public let studios: [Studio]
  public let next_episode_at: Date?
  public let rating: String?
}

public struct AnimePreview: Sendable, Decodable {
  public let id: Int
  public let name: String
  public let russian: String?
  public let kind: AnimeKind?
  public let score: String?
  public let image: ImageVariants?
  public let aired_on: String?
}
