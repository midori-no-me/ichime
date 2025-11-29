import Foundation

public struct GraphQLAnimeScreenshot: Sendable, Decodable {
  public struct Screenshot: Sendable, Decodable {
    public let originalUrl: URL
  }

  public let screenshots: [Screenshot]
}
