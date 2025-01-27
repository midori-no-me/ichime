import Foundation
import JikanApiClient

public struct StaffMember: Identifiable {
  public let id: Int
  public let image: URL?
  public let name: String
  public let roles: [String]

  static func create(
    jikanStaffMember: JikanApiClient.StaffMember
  ) -> Self {
    .init(
      id: jikanStaffMember.person.mal_id,
      image: jikanStaffMember.person.images.jpg.image_url,
      name: jikanStaffMember.person.name,
      roles: jikanStaffMember.positions
    )
  }
}
