import Foundation
import OSLog

public class ApiClient {
  public let baseUrl: URL

  private let userAgent: String
  private let logger: Logger

  public init(
    baseUrl: URL,
    userAgent: String,
    logger: Logger
  ) {
    self.baseUrl = baseUrl
    self.userAgent = userAgent
    self.logger = logger
  }

  func sendRequest<T: Decodable>(
    endpoint: String,
    queryItems: [URLQueryItem]
  ) async throws -> T {
    (try await self.sendRequestInternal(endpoint: endpoint, queryItems: queryItems))
      .data
  }

  func sendRequestWithPagination<T: Decodable>(
    endpoint: String,
    queryItems: [URLQueryItem]
  ) async throws -> (data: T, hasMore: Bool) {
    let apiResponse: ApiResponse<T> = try await self.sendRequestInternal(endpoint: endpoint, queryItems: queryItems)

    return (data: apiResponse.data, hasMore: apiResponse.pagination?.has_next_page ?? false)
  }

  private func sendRequestInternal<T: Decodable>(
    endpoint: String,
    queryItems: [URLQueryItem]
  ) async throws -> ApiResponse<T> {
    var fullURL = self.baseUrl.appendingPathComponent(endpoint)

    if !queryItems.isEmpty {
      fullURL.append(queryItems: queryItems.sorted(by: { $0.name < $1.name }))
    }

    var httpRequest = URLRequest(url: fullURL)

    httpRequest.timeoutInterval = 3
    httpRequest.httpMethod = "GET"
    httpRequest.setValue("application/json", forHTTPHeaderField: "Accept")
    httpRequest.setValue(self.userAgent, forHTTPHeaderField: "User-Agent")

    let (data, httpResponse) = try await URLSession.shared.data(for: httpRequest)

    if let requestUrl = httpRequest.url?.absoluteString,
      let httpResponse = httpResponse as? HTTPURLResponse
    {
      self.logger.info("API request: GET \(requestUrl) [\(httpResponse.statusCode)]")
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
