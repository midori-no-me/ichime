import Foundation

public struct Anime: Sendable, Decodable {
  public struct Broadcast: Sendable, Decodable {
    public let day: String?
    public let time: String?
    public let timezone: String?
  }

  public let mal_id: Int
  public let images: ImageInDifferentFormats
  public let title: String
  public let broadcast: Broadcast
  public let scored_by: Int?
  public let rank: Int?
  public let popularity: Int?
  public let members: Int?
  public let favorites: Int?
  public let source: String?
  public let season: Season?
  public let year: Int?
}
