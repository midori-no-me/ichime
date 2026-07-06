import Foundation
import OSLog

enum HttpMethod: String {
  case GET
  case POST
  case PATCH
  case PUT
  case DELETE
}

public struct ApiClient: Sendable {
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
    httpMethod: HttpMethod,
    endpoint: String,
    queryItems: [URLQueryItem],
    requestBody: Encodable?
  ) async throws -> T {
    var fullURL = self.baseUrl.appendingPathComponent(endpoint)

    if !queryItems.isEmpty {
      fullURL.append(queryItems: queryItems.sorted(by: { $0.name < $1.name }))
    }

    var httpRequest = URLRequest(url: fullURL)

    httpRequest.timeoutInterval = 5
    httpRequest.httpMethod = httpMethod.rawValue

    httpRequest.setValue("application/json", forHTTPHeaderField: "Accept")

    if let requestBody = requestBody {
      httpRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

      do {
        let requestBodyJson = try JSONEncoder().encode(requestBody)

        httpRequest.httpBody = requestBodyJson
      }
      catch {
        throw ApiClientError.canNotEncodeRequestJson
      }
    }

    let (data, httpResponse) = try await self.urlSession.data(for: httpRequest)

    if let requestUrl = httpRequest.url?.absoluteString,
      let httpResponse = httpResponse as? HTTPURLResponse
    {
      self.logger.info("API request: \(httpMethod.rawValue) \(requestUrl) [\(httpResponse.statusCode)]")
    }

    do {
      let jsonDecoder = JSONDecoder()

      jsonDecoder.dateDecodingStrategy = ApiDateDecoder.getDateDecodingStrategy()

      let apiResponse = try jsonDecoder.decode(T.self, from: data)

      return apiResponse
    }
    catch {
      let debugApiResponse = String(data: data, encoding: .utf8) ?? "Unable to convert response body to a string"

      self.logger.error("Decoding JSON into \(T.self) error:\n\n\(error)\n\nAPI response:\n\n\(debugApiResponse)")

      throw ApiClientError.canNotDecodeResponseJson
    }
  }
}
