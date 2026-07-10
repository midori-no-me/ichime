import IchimeShow
import SwiftUI

struct CharacterCard: View {
  // MARK: Properties

  let character: CharacterInfo

  // MARK: Content Properties

  var body: some View {
    CircularPortraitButton.button(
      imageURL: self.character.image,
      label: self.character.name,
      secondaryLabel: self.character.role,
      action: {},
    )
  }
}
