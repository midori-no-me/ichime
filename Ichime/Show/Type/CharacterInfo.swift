import Foundation
import OrderedCollections
import ShikimoriApiClient

struct CharacterInfo: Identifiable, Hashable {
  let id: String
  let image: URL?
  let name: String
  let role: String

  init(
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

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
  }
}
