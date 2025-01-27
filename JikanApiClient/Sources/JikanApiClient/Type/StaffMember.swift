import Foundation

public struct StaffMember: Decodable {
  public let person: Person
  public let positions: [String]
}
