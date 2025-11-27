public struct Genre: Sendable, Decodable {
  public enum EntryType: String, Sendable, Decodable {
    case manga = "Manga"
    case anime = "Anime"
  }

  public let id: Int
  public let russian: String
  public let entry_type: EntryType
}
