import SwiftUI

struct VoiceActorCard: View {
  let voiceActor: CharacterInfo.VoiceActor

  var body: some View {
    CircularPortraitButton(
      imageUrl: self.voiceActor.image,
      action: {},
      label: {
        VStack {
          Text(self.voiceActor.name)
            .lineLimit(1)

          Text(self.voiceActor.language)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }
    )
  }
}
