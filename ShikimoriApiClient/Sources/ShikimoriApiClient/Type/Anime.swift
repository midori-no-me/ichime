import Foundation

public struct Anime: Decodable {
  public struct Studio: Decodable {
    public let id: Int
    public let filtered_name: String
    public let image: String?
  }

  public let studios: [Studio]
  public let next_episode_at: Date?
}

public struct AnimePreview: Decodable {
  public let id: Int
  public let name: String
  public let russian: String?
  public let kind: AnimeKind?
  public let score: String?
  public let image: ImageVariants?
  public let aired_on: String?
}
