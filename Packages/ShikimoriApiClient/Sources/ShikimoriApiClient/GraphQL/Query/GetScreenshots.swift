import Foundation

// swiftformat:disable acronyms

public struct GetScreenshotsResponse: Sendable, Decodable {
  // MARK: Nested Types

  public struct AnimeFields: Sendable, Decodable {
    // MARK: Nested Types

    public struct Screenshot: Sendable, Decodable {
      public let originalUrl: URL
    }

    // MARK: Properties

    public let screenshots: [Screenshot]
  }

  // MARK: Properties

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
