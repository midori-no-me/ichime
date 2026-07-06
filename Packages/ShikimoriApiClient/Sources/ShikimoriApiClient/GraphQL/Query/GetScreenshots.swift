import Foundation

public struct GetScreenshotsResponse: Sendable, Decodable {
  public struct AnimeFields: Sendable, Decodable {
    public struct Screenshot: Sendable, Decodable {
      public let originalUrl: URL
    }

    public let screenshots: [Screenshot]
  }

  public let animes: [AnimeFields]
}

extension GraphQLClient {
  public func getScreenshots(
    id: Int,
  ) async throws -> GetScreenshotsResponse {
    let query = """
      query GetScreenshots($id: String) {
        animes(ids: $id) {
          screenshots { originalUrl }
        }
      }
      """

    let variables: [String: AnyEncodable] = [
      "id": AnyEncodable(String(id))
    ]

    return try await sendRequest(
      operationName: "GetScreenshots",
      variables: variables,
      query: query,
    )
  }
}
