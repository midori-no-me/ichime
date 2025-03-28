import Foundation

public struct Episode: Decodable {
  public let mal_id: Int
  public let title: String
  public let aired: Date?
  public let score: Float?
  public let filler: Bool
  public let recap: Bool
  public let synopsis: String?
  public let duration: Int?
}
