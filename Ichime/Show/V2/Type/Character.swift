import Foundation
import JikanApiClient

struct Character: Identifiable {
  struct VoiceActor: Identifiable {
    let id: Int
    let name: String
    let image: URL?
    let language: String
  }

  let id: Int
  let image: URL?
  let name: String
  let role: String
  let voiceActors: [VoiceActor]

  static func create(
    jikanCharacterRole: JikanApiClient.CharacterRole
  ) -> Self {
    var imageUrl: URL? = jikanCharacterRole.character.images.jpg.image_url

    if let nonNilImageUrl = imageUrl, nonNilImageUrl.path().contains("questionmark") {
      imageUrl = nil
    }

    return .init(
      id: jikanCharacterRole.character.mal_id,
      image: imageUrl,
      name: jikanCharacterRole.character.name,
      role: jikanCharacterRole.role,
      voiceActors: jikanCharacterRole.voice_actors.map {
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
}
