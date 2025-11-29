import Foundation

public struct GetRelatedResponse: Sendable, Decodable {
  public let animes: [GraphQLAnimeWithRelations]
}

extension GraphQLClient {
  public func getRelated(
    id: Int,
  ) async throws -> GetRelatedResponse {
    let query = """
      query GetRelated($id: String) {
        animes(ids: $id) {
          related {
            relationKind
            anime {
              malId
              name
              russian
              kind
              score
              season
              poster {
                previewAlt2xUrl
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
      operationName: "GetRelated",
      variables: variables,
      query: query,
    )
  }
}
