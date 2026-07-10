import Foundation

public struct AnimeFieldsForPreview: Sendable, Decodable {
  // MARK: Nested Types

  public struct Poster: Sendable, Decodable {
    public let previewAlt2xUrl: URL
  }

  // MARK: Properties

  public let malId: String?
  public let name: String
  public let russian: String?
  public let kind: AnimeKind?
  public let score: Float?
  public let season: String?
  public let airedOn: IncompleteDate
  public let poster: Poster?
}
