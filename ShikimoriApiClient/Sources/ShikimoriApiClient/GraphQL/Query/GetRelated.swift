import Foundation

public struct GetRelatedResponse: Sendable, Decodable {
  public struct AnimeFields: Sendable, Decodable {
    public struct Relation: Sendable, Decodable {
      public let relationKind: RelationKind
      public let anime: AnimeFieldsForPreview?
    }

    public let related: [Relation]
  }

  public let animes: [AnimeFields]
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
