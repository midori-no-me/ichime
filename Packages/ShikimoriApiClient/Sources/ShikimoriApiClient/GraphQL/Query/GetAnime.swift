import Foundation

public struct GetAnimeResponse: Sendable, Decodable {
  // MARK: Nested Types

  public struct Anime: Sendable, Decodable {
    // MARK: Nested Types

    public struct Studio: Sendable, Decodable {
      public let id: String
      public let name: String
      public let imageUrl: URL?
    }

    // MARK: Properties

    public let airedOn: IncompleteDate
    public let studios: [Studio]
    public let nextEpisodeAt: Date?
    public let rating: String?
  }

  // MARK: Properties

  public let animes: [Anime]
}

extension GraphQLClient {
  public func getAnime(id: Int) async throws -> GetAnimeResponse.Anime? {
    let query = """
      query GetAnime($id: String) {
        animes(ids: $id) {
          airedOn { year }
          studios { id, name, imageUrl }
          nextEpisodeAt
          rating
        }
      }
      """

    let variables: [String: AnyEncodable] = [
      "id": AnyEncodable(String(id))
    ]

    let response: GetAnimeResponse = try await sendRequest(
      operationName: "GetAnime",
      variables: variables,
      query: query,
    )

    return response.animes.first
  }
}
