import Foundation

public struct Character: Sendable, Decodable {
  public let mal_id: Int
  public let name: String
  public let images: ImageInDifferentFormats
}
