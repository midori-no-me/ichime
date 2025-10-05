import SwiftUI

struct VoiceActorCard: View {
  let voiceActor: CharacterInfo.VoiceActor

  var body: some View {
    CircularPortraitButton.button(
      imageUrl: self.voiceActor.image,
      label: self.voiceActor.name,
      secondaryLabel: self.voiceActor.language,
      action: {},
    )
  }
}
