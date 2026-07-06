import Foundation

public struct GetCharactersResponse: Sendable, Decodable {
  public struct AnimeFields: Sendable, Decodable {
    public struct CharacterRole: Sendable, Decodable {
      public struct Character: Sendable, Decodable {
        public struct Poster: Sendable, Decodable {
          public let mainAlt2xUrl: URL
        }

        public let name: String
        public let poster: Poster?
      }

      public let id: String
      public let rolesRu: [String]
      public let character: Character
    }

    public let characterRoles: [CharacterRole]
  }

  public let animes: [AnimeFields]
}

extension GraphQLClient {
  public func getCharacters(
    id: Int,
  ) async throws -> GetCharactersResponse {
    let query = """
      query GetCharacters($id: String) {
        animes(ids: $id) {
          characterRoles {
            id
            rolesRu
            character {
              name
              poster {
                mainAlt2xUrl
              }
            }
          }
        }
      }
      """

    let variables: [String: AnyEncodable] = [
      "id": AnyEncodable(String(id))
    ]

    return try await sendRequest(
      operationName: "GetCharacters",
      variables: variables,
      query: query,
    )
  }
}
