import Foundation

public struct Relation: Decodable {
  public struct Anime: Decodable {
    public struct Image: Decodable {
      public let original: String
      public let preview: String
      public let x96: String
      public let x48: String
    }

    public let id: Int
    public let name: String
    public let russian: String?
    public let kind: String?
    public let score: String?
    public let image: Image?
    public let aired_on: String?
  }

  public let relation_russian: String
  public let anime: Anime?
}
