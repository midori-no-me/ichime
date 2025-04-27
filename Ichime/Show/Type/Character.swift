import Foundation
import JikanApiClient
import OrderedCollections

struct Character: Identifiable, Hashable {
  struct VoiceActor: Identifiable, Hashable {
    let id: Int
    let name: String
    let image: URL?
    let language: String
  }

  let id: Int
  let image: URL?
  let name: String
  let role: String
  let voiceActors: OrderedSet<VoiceActor>

  init(
    fromJikanCharacterRole: JikanApiClient.CharacterRole
  ) {
    if let imageUrl = fromJikanCharacterRole.character.images.jpg.image_url, !imageUrl.path().contains("questionmark") {
      self.image = imageUrl
    }
    else {
      self.image = nil
    }

    self.id = fromJikanCharacterRole.character.mal_id
    self.name = fromJikanCharacterRole.character.name
    self.role = fromJikanCharacterRole.role
    self.voiceActors = .init(
      fromJikanCharacterRole.voice_actors.map {
        .init(
          id: $0.person.mal_id,
          name: $0.person.name,
          image: ($0.person.images.jpg.image_url?.path().contains("questionmark") ?? true)
            ? nil : $0.person.images.jpg.image_url,
          language: $0.language
        )
      }
    )
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
  }
}
