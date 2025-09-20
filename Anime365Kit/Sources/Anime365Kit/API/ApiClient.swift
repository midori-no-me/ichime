import Foundation
import OSLog

public class ApiClient {
  private let baseURL: URL
  private let userAgent: String
  private let urlSession: URLSession
  private let jsonDecoder: JSONDecoder
  private let logger: Logger

  public init(
    baseURL: URL,
    userAgent: String,
    logger: Logger,
    urlSession: URLSession
  ) {
    self.baseURL = baseURL
    self.userAgent = userAgent

    let jsonDecoder = JSONDecoder.init()
    jsonDecoder.dateDecodingStrategy = ApiDateDecoder.getDateDecodingStrategy()

    self.jsonDecoder = jsonDecoder
    self.logger = logger
    self.urlSession = urlSession
  }

  func sendRequest<T: Decodable>(
    endpoint: String,
    queryItems: [URLQueryItem]
  ) async throws -> T {
    // Составляем URL запроса
    var fullURL = self.baseURL.appendingPathComponent("/api" + endpoint)

    if !queryItems.isEmpty {
      fullURL.append(queryItems: queryItems.sorted(by: { $0.name < $1.name }))
    }

    var httpRequest = URLRequest(url: fullURL)

    httpRequest.timeoutInterval = 10
    httpRequest.httpMethod = "GET"

    httpRequest.setValue("application/json", forHTTPHeaderField: "Accept")
    httpRequest.setValue(self.userAgent, forHTTPHeaderField: "User-Agent")

    let (data, httpResponse) = try await self.urlSession.data(for: httpRequest)

    if let httpResponse = httpResponse as? HTTPURLResponse {
      self.logger.debug("API request: \(httpRequest.httpMethod!) \(httpRequest.url!) [\(httpResponse.statusCode)]")
    }

    do {
      let apiResponse = try self.jsonDecoder.decode(ApiResponse<T>.self, from: data)

      return apiResponse.data
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
