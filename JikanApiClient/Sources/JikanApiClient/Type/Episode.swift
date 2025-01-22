import Foundation

public struct Episode: Decodable {
  public let mal_id: Int
  public let title: String
  public let aired: String?
  public let score: Float
  public let filler: Bool
  public let recap: Bool
}
