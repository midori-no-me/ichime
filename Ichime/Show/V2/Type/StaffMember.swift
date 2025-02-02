import Foundation
import JikanApiClient

struct StaffMember: Identifiable {
  let id: Int
  let image: URL?
  let name: String
  let roles: [String]

  static func create(
    jikanStaffMember: JikanApiClient.StaffMember
  ) -> Self {
    var imageUrl: URL? = jikanStaffMember.person.images.jpg.image_url

    if let nonNilImageUrl = imageUrl, nonNilImageUrl.path().contains("questionmark") {
      imageUrl = nil
    }

    return .init(
      id: jikanStaffMember.person.mal_id,
      image: imageUrl,
      name: jikanStaffMember.person.name,
      roles: jikanStaffMember.positions
    )
  }
}
