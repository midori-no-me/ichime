import SwiftUI

struct CharacterCard: View {
  @State private var isSheetPresented = false

  let character: Character

  var body: some View {
    CircularPortraitButton(
      imageUrl: self.character.image,
      action: { self.isSheetPresented = true },
      label: {
        Text(self.character.name).lineLimit(1)
      }
    )
    .sheet(isPresented: self.$isSheetPresented) {
      CharacterCardSheet(character: self.character)
    }
  }
}

private struct CharacterCardSheet: View {
  let character: Character

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ScrollView(.vertical) {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 64), count: 6), spacing: 64) {
          ForEach(self.character.voiceActors) { voiceActor in
            VoiceActorCard(voiceActor: voiceActor)
          }
        }
      }
    }
  }
}
