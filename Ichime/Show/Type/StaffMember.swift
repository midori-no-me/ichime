import Foundation
import JikanApiClient

struct StaffMember: Identifiable, Hashable {
  let id: Int
  let image: URL?
  let name: String
  let roles: [String]

  init(
    fromJikanStaffMember: JikanApiClient.StaffMember
  ) {
    if let imageUrl = fromJikanStaffMember.person.images.jpg.image_url, !imageUrl.path().contains("questionmark") {
      self.image = imageUrl
    }
    else {
      self.image = nil
    }

    self.id = fromJikanStaffMember.person.mal_id
    self.name = fromJikanStaffMember.person.name
    self.roles = fromJikanStaffMember.positions
  }
}
