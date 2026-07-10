public struct Genre: Sendable, Decodable {
  // MARK: Nested Types

  public enum EntryType: String, Sendable, Decodable {
    case manga = "Manga"
    case anime = "Anime"
  }

  // MARK: Properties

  public let id: Int
  public let russian: String
  public let entry_type: EntryType
}
