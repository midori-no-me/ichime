import Foundation

public struct VoiceActor: Sendable, Decodable {
  public let person: Person
  public let language: String
}
