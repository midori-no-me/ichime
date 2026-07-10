import Foundation
import OSLog

public struct ApiClient: Sendable {
  public let baseURL: URL

  private let urlSession: URLSession
  private let logger: Logger

  public init(
    baseURL: URL,
    urlSession: URLSession,
    logger: Logger
  ) {
    self.baseURL = baseURL
    self.urlSession = urlSession
    self.logger = logger
  }

  func sendRequest<T: Decodable>(
    endpoint: String,
    queryItems: [URLQueryItem]
  ) async throws -> T {
    (try await self.sendRequestInternal(endpoint: endpoint, queryItems: queryItems))
      .data
  }

  private func sendRequestInternal<T: Decodable>(
    endpoint: String,
    queryItems: [URLQueryItem]
  ) async throws -> ApiResponse<T> {
    var fullURL = self.baseURL.appendingPathComponent(endpoint)

    if !queryItems.isEmpty {
      fullURL.append(queryItems: queryItems.sorted(by: { $0.name < $1.name }))
    }

    var httpRequest = URLRequest(url: fullURL)

    httpRequest.timeoutInterval = 3
    httpRequest.httpMethod = "GET"
    httpRequest.setValue("application/json", forHTTPHeaderField: "Accept")

    let (data, httpResponse) = try await self.urlSession.data(for: httpRequest)

    if let requestURL = httpRequest.url?.absoluteString,
      let httpResponse = httpResponse as? HTTPURLResponse
    {
      self.logger.info("API request: GET \(requestURL) [\(httpResponse.statusCode)]")
    }

    do {
      let jsonDecoder = JSONDecoder()

      jsonDecoder.dateDecodingStrategy = .iso8601

      let apiResponse = try jsonDecoder.decode(ApiResponse<T>.self, from: data)

      return apiResponse
    }
    catch {
      let debugApiResponse = String(data: data, encoding: .utf8) ?? "Unable to convert response body to a string"

      self.logger.error(
        "Decoding JSON into \(ApiResponse<T>.self) error:\n\n\(error)\n\nAPI response:\n\n\(debugApiResponse)"
      )

      throw ApiClientError.canNotDecodeResponseJson
    }
  }
}
