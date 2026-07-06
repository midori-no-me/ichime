import Foundation
import ShikimoriApiClient

struct StaffMember: Identifiable, Hashable {
  let id: String
  let image: URL?
  let name: String
  let roles: [String]

  init(
    fromShikimoriPersonRole: ShikimoriApiClient.GetStaffResponse.AnimeFields.PersonRole
  ) {
    if let poster = fromShikimoriPersonRole.person.poster {
      self.image = poster.mainAlt2xUrl
    }
    else {
      self.image = nil
    }

    self.id = fromShikimoriPersonRole.id
    self.name = fromShikimoriPersonRole.person.name
    self.roles = fromShikimoriPersonRole.rolesRu
  }
}
