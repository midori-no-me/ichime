import IchimeShow
import SwiftUI

struct StaffMemberCard: View {
  let staffMember: StaffMember

  var body: some View {
    CircularPortraitButton.button(
      imageURL: self.staffMember.image,
      label: self.staffMember.name,
      secondaryLabel: self.staffMember.roles.first,
      action: {},
    )
  }
}
