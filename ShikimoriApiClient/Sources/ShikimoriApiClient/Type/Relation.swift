import Foundation

public struct Relation: Sendable, Decodable {
  public struct Anime: Sendable, Decodable {
    public let id: Int
    public let name: String
    public let russian: String?
    public let kind: AnimeKind?
    public let score: String?
    public let image: ImageVariants?
    public let aired_on: String?
  }

  public let relation_russian: String
  public let anime: Anime?
}
