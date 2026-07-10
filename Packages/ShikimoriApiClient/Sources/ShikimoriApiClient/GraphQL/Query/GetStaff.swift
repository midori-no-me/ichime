import Foundation

// swiftformat:disable acronyms

public struct GetStaffResponse: Sendable, Decodable {
  // MARK: Nested Types

  public struct AnimeFields: Sendable, Decodable {
    // MARK: Nested Types

    public struct PersonRole: Sendable, Decodable {
      // MARK: Nested Types

      public struct Person: Sendable, Decodable {
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
      public let person: Person
    }

    // MARK: Properties

    public let personRoles: [PersonRole]
  }

  // MARK: Properties

  public let animes: [AnimeFields]
}

extension GraphQLClient {
  public func getStaff(
    id: Int,
  ) async throws -> GetStaffResponse {
    let query = """
      query GetStaff($id: String) {
        animes(ids: $id) {
          personRoles {
            id
            rolesRu
            person {
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
      operationName: "GetStaff",
      variables: variables,
      query: query,
    )
  }
}
