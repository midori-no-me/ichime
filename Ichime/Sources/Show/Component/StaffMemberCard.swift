import IchimeShow
import SwiftUI

struct StaffMemberCard: View {
  // MARK: Properties

  let staffMember: StaffMember

  // MARK: Content Properties

  var body: some View {
    CircularPortraitButton.button(
      imageURL: self.staffMember.image,
      label: self.staffMember.name,
      secondaryLabel: self.staffMember.roles.first,
      action: {},
    )
  }
}
