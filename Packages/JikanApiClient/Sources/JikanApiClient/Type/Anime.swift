import Foundation

public struct Anime: Sendable, Decodable {
  public let season: Season?
  public let year: Int?
  public let aired: DateRange
}
