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
  ) async throws(ApiClientError) -> T {
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

    var data: Data
    var urlResponse: URLResponse

    do {
      (data, urlResponse) = try await self.urlSession.data(for: httpRequest)
    }
    catch {
      self.logger.debug("Error after sending \(URLSession.self) request: \(error)")
      throw .requestFailed
    }

    if let httpResponse = urlResponse as? HTTPURLResponse {
      self.logger.debug("API request: \(httpRequest.httpMethod!) \(httpRequest.url!) [\(httpResponse.statusCode)]")
    }

    let apiErrorResponse = try? self.jsonDecoder.decode(ApiErrorResponse.self, from: data)

    if let apiErrorResponse {
      let debugApiResponse = String(data: data, encoding: .utf8) ?? "Unable to convert response body to a string"

      self.logger.warning("API error:\n\n\(debugApiResponse)")

      if apiErrorResponse.error.code == 403 {
        throw .apiError(.authenticationRequired)
      }

      throw .apiError(.other(apiErrorResponse.error.code, apiErrorResponse.error.message))
    }

    do {
      let apiResponse = try self.jsonDecoder.decode(ApiSuccessfulResponse<T>.self, from: data)

      return apiResponse.data
    }
    catch {
      let debugApiResponse = String(data: data, encoding: .utf8) ?? "Unable to convert response body to a string"

      self.logger.error(
        "Decoding JSON into \(ApiSuccessfulResponse<T>.self) error:\n\n\(error)\n\nAPI response:\n\n\(debugApiResponse)"
      )

      throw .canNotDecodeResponseJson
    }
  }
}
