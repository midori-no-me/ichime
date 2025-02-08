import Foundation
import OSLog

public class ApiClient {
  public let baseURL: URL

  private let userAgent: String
  private let urlSession: URLSession
  private let logger: Logger

  public init(
    baseURL: URL,
    userAgent: String,
    cookieStorage: HTTPCookieStorage,
    logger: Logger
  ) {
    self.baseURL = baseURL
    self.userAgent = userAgent
    let config = URLSessionConfiguration.default
    config.httpCookieStorage = cookieStorage
    self.urlSession = URLSession(configuration: config)
    self.logger = logger
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

    if let requestUrl = httpRequest.url?.absoluteString,
      let httpResponse = httpResponse as? HTTPURLResponse
    {
      self.logger.info("API request: GET \(requestUrl) [\(httpResponse.statusCode)]")
    }
    do {
      let jsonDecoder = JSONDecoder()

      jsonDecoder.dateDecodingStrategy = ApiDateDecoder.getDateDecodingStrategy()

      let apiResponse = try jsonDecoder.decode(ApiResponse<T>.self, from: data)

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
