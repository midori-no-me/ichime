import Foundation
import JikanApiClient

public struct Character: Identifiable {
  public struct VoiceActor: Identifiable {
    public let id: Int
    public let name: String
    public let image: URL?
    public let language: String
  }

  public let id: Int
  public let image: URL?
  public let name: String
  public let role: String
  public let voiceActors: [VoiceActor]

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
          image: $0.person.images.jpg.image_url,
          language: $0.language
        )
      }
    )
  }
}
