import Foundation

public struct GetCharactersResponse: Sendable, Decodable {
  // MARK: Nested Types

  public struct AnimeFields: Sendable, Decodable {
    // MARK: Nested Types

    public struct CharacterRole: Sendable, Decodable {
      // MARK: Nested Types

      public struct Character: Sendable, Decodable {
        // MARK: Nested Types

        public struct Poster: Sendable, Decodable {
          public let mainAlt2xUrl: URL
        }

        // MARK: Properties

        public let name: String
        public let poster: Poster?
      }

      // MARK: Properties

      public let id: String
      public let rolesRu: [String]
      public let character: Character
    }

    // MARK: Properties

    public let characterRoles: [CharacterRole]
  }

  // MARK: Properties

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
