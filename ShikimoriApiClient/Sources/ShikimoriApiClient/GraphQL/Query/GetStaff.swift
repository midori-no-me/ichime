import Foundation

public struct GetStaffResponse: Sendable, Decodable {
  public struct AnimeFields: Sendable, Decodable {
    public struct PersonRole: Sendable, Decodable {
      public struct Person: Sendable, Decodable {
        public struct Poster: Sendable, Decodable {
          public let mainAlt2xUrl: URL
        }

        public let name: String
        public let poster: Poster?
      }

      public let id: String
      public let rolesRu: [String]
      public let person: Person
    }

    public let personRoles: [PersonRole]
  }

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
