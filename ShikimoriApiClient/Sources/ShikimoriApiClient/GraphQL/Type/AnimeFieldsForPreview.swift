import Foundation

public struct AnimeFieldsForPreview: Sendable, Decodable {
  public struct Poster: Sendable, Decodable {
    public let previewAlt2xUrl: URL
  }

  public let malId: String?
  public let name: String
  public let russian: String?
  public let kind: AnimeKind?
  public let score: Float?
  public let season: String?
  public let poster: Poster?
}
