import SwiftUI

struct StaffMemberCard: View {
  let staffMember: StaffMember

  var body: some View {
    CircularPortraitButton(
      imageUrl: self.staffMember.image,
      action: {},
      label: {
        Text(self.staffMember.name)
          .lineLimit(1)

        Text(self.staffMember.roles.first ?? "")
          .foregroundStyle(.secondary)
          .lineLimit(1, reservesSpace: true)
      }
    )
  }
}
