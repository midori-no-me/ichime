import Foundation

public struct StaffMember: Sendable, Decodable {
  public let person: Person
  public let positions: [String]
}
