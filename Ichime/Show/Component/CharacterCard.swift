import SwiftUI

struct CharacterCard: View {
  @State private var isSheetPresented = false

  let character: CharacterInfo

  var body: some View {
    CircularPortraitButton.button(
      imageUrl: self.character.image,
      label: self.character.name,
      secondaryLabel: self.character.role,
      action: { self.isSheetPresented = true },
    )
    .fullScreenCover(isPresented: self.$isSheetPresented) {
      CharacterCardSheet(character: self.character)
        .background(.thickMaterial)  // Костыль для обхода бага: .fullScreenCover на tvOS 26 не имеет бекграунда
    }
  }
}

private struct CharacterCardSheet: View {
  let character: CharacterInfo

  var body: some View {
    NavigationStack {
      if !self.character.voiceActors.isEmpty {
        ScrollView(.vertical) {
          SectionWithCards(title: "Актёры лицензионной озвучки") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 64), count: 6), spacing: 64) {
              ForEach(self.character.voiceActors) { voiceActor in
                VoiceActorCard(voiceActor: voiceActor)
              }
            }
          }
        }
      }
      else {
        ContentUnavailableView(
          "Ничего не нашлось",
          systemImage: "person.circle",
          description: Text("У этого персонажа не указали актёров лицензионной озвучки, поэтому тут ничего нет")
        )
      }
    }
  }
}
