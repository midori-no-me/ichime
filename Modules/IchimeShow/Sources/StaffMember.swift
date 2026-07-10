import Foundation
import ShikimoriApiClient

public struct StaffMember: Identifiable, Hashable {
  // MARK: Properties

  public let id: String
  public let image: URL?
  public let name: String
  public let roles: [String]

  // MARK: Lifecycle

  public init(
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
