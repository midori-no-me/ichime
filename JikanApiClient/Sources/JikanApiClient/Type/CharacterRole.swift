public struct CharacterRole: Decodable {
  public let character: Character
  public let role: String
  public let voice_actors: [VoiceActor]
}
