import Foundation

public struct IncompleteDate: Sendable, Decodable {
  public let month: Int?
  public let year: Int?
}
