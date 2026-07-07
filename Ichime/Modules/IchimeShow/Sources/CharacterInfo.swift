import Foundation
import OrderedCollections
import ShikimoriApiClient

public struct CharacterInfo: Identifiable, Hashable {
  public let id: String
  public let image: URL?
  public let name: String
  public let role: String

  public init(
    fromShikimoriCharacterRole: ShikimoriApiClient.GetCharactersResponse.AnimeFields.CharacterRole
  ) {
    if let poster = fromShikimoriCharacterRole.character.poster {
      self.image = poster.mainAlt2xUrl
    }
    else {
      self.image = nil
    }

    self.id = fromShikimoriCharacterRole.id
    self.name = fromShikimoriCharacterRole.character.name
    self.role = fromShikimoriCharacterRole.rolesRu.joined(separator: ", ")
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
  }
}
