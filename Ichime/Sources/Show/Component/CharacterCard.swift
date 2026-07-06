import SwiftUI

struct CharacterCard: View {
  let character: CharacterInfo

  var body: some View {
    CircularPortraitButton.button(
      imageUrl: self.character.image,
      label: self.character.name,
      secondaryLabel: self.character.role,
      action: {},
    )
  }
}
