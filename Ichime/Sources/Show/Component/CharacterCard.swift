import IchimeShow
import SwiftUI

struct CharacterCard: View {
  let character: CharacterInfo

  var body: some View {
    CircularPortraitButton.button(
      imageURL: self.character.image,
      label: self.character.name,
      secondaryLabel: self.character.role,
      action: {},
    )
  }
}
