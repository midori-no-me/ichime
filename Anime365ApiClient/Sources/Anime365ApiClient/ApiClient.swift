import Foundation

public class ApiClient {
  private let baseURL: URL
  private let userAgent: String
  private let urlSession: URLSession

  public init(
    baseURL: URL,
    userAgent: String,
    cookieStorage: HTTPCookieStorage
  ) {
    self.baseURL = baseURL
    self.userAgent = userAgent
    let config = URLSessionConfiguration.default
    config.httpCookieStorage = cookieStorage
    self.urlSession = URLSession(configuration: config)
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
    httpRequest.setValue("application/json", forHTTPHeaderField: "Accept")
    httpRequest.setValue(self.userAgent, forHTTPHeaderField: "User-Agent")
    httpRequest.timeoutInterval = 3

    let (data, httpResponse) = try await self.urlSession.data(for: httpRequest)

    if let requestUrl = httpRequest.url?.absoluteString,
      let httpResponse = httpResponse as? HTTPURLResponse
    {
      print(
        "[Anime365ApiClient] API request: GET \(requestUrl) [\(httpResponse.statusCode)]"
      )
    }
    do {
      let jsonDecoder = JSONDecoder()

      jsonDecoder.dateDecodingStrategy = ApiDateDecoder.getDateDecodingStrategy()

      let apiResponse = try jsonDecoder.decode(ApiResponse<T>.self, from: data)

      return apiResponse.data
    }
    catch {
      print("[Anime365ApiClient] Decoding JSON error: \(error.localizedDescription)")
      print("[Anime365ApiClient] JSON Decoder detailed error:")
      print(error)
      print("[Anime365ApiClient] API response:")

      if let responseBodyString = String(data: data, encoding: .utf8) {
        print(responseBodyString)
      }
      else {
        print("[Anime365ApiClient] Unable to convert response body to a string")
      }

      throw ApiClientError.canNotDecodeResponseJson
    }
  }
}
