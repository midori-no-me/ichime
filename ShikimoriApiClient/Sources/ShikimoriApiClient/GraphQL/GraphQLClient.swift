import Foundation
import OSLog

public struct GraphQLClient: Sendable {
  public let baseUrl: URL

  private let urlSession: URLSession
  private let logger: Logger

  public init(
    baseUrl: URL,
    urlSession: URLSession,
    logger: Logger
  ) {
    self.baseUrl = baseUrl
    self.urlSession = urlSession
    self.logger = logger
  }

  func sendRequest<T: Decodable>(
    operationName: String,
    variables: [String: some Encodable & Sendable],
    query: String
  ) async throws -> T {
    let fullURL = self.baseUrl.appendingPathComponent("/api/graphql")

    var httpRequest = URLRequest(url: fullURL)

    httpRequest.timeoutInterval = 5
    httpRequest.httpMethod = "POST"

    httpRequest.setValue("application/json", forHTTPHeaderField: "Accept")
    httpRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

    do {
      let requestBodyJson = try JSONEncoder().encode(
        GraphQLRequest(
          operationName: operationName,
          variables: variables,
          query: query,
        )
      )

      httpRequest.httpBody = requestBodyJson
    }
    catch {
      throw ApiClientError.canNotEncodeRequestJson
    }

    let (data, httpResponse) = try await self.urlSession.data(for: httpRequest)

    if let httpResponse = httpResponse as? HTTPURLResponse {
      // Convert variables to readable JSON for logging
      let variablesLogString: String
      do {
        let jsonData = try JSONEncoder().encode(variables)
        if let jsonString = String(data: jsonData, encoding: .utf8) {
          variablesLogString = jsonString
        }
        else {
          variablesLogString = "Unable to convert variables to string"
        }
      }
      catch {
        variablesLogString = "Error encoding variables: \(error)"
      }

      self.logger.info("GraphQL request: \(operationName)(\(variablesLogString)) [\(httpResponse.statusCode)]")
    }

    do {
      let jsonDecoder = JSONDecoder()

      jsonDecoder.dateDecodingStrategy = ApiDateDecoder.getDateDecodingStrategy()

      let apiResponse = try jsonDecoder.decode(GraphQLResponse<T>.self, from: data)

      return apiResponse.data
    }
    catch {
      let debugApiResponse = String(data: data, encoding: .utf8) ?? "Unable to convert response body to a string"

      self.logger.error(
        "Decoding JSON into \(GraphQLResponse<T>.self) error:\n\n\(error)\n\nGraphQL API response:\n\n\(debugApiResponse)"
      )

      throw ApiClientError.canNotDecodeResponseJson
    }
  }
}
