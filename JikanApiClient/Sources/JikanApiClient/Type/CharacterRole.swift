public struct CharacterRole: Sendable, Decodable {
  public let character: Character
  public let role: String
  public let voice_actors: [VoiceActor]
}
