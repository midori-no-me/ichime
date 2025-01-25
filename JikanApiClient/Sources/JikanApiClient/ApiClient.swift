import Foundation

public class ApiClient {
  public let baseUrl: URL

  private let userAgent: String

  public init(
    baseUrl: URL,
    userAgent: String
  ) {
    self.baseUrl = baseUrl
    self.userAgent = userAgent
  }

  func sendRequest<T: Decodable>(
    endpoint: String,
    queryItems: [URLQueryItem]
  ) async throws -> T {
    var fullURL = self.baseUrl.appendingPathComponent(endpoint)

    if !queryItems.isEmpty {
      fullURL.append(queryItems: queryItems.sorted(by: { $0.name < $1.name }))
    }

    var httpRequest = URLRequest(url: fullURL)

    httpRequest.httpMethod = "GET"

    httpRequest.setValue("application/json", forHTTPHeaderField: "Accept")
    httpRequest.setValue(self.userAgent, forHTTPHeaderField: "User-Agent")

    let (data, httpResponse) = try await URLSession.shared.data(for: httpRequest)

    if let requestUrl = httpRequest.url?.absoluteString,
      let httpResponse = httpResponse as? HTTPURLResponse
    {
      print(
        "[JikanApiClient] API request: GET \(requestUrl) [\(httpResponse.statusCode)]"
      )
    }

    do {
      let jsonDecoder = JSONDecoder()

      jsonDecoder.dateDecodingStrategy = .iso8601

      let apiResponse = try jsonDecoder.decode(ApiResponse<T>.self, from: data)

      return apiResponse.data
    }
    catch {
      print("[JikanApiClient] Decoding JSON error: \(error.localizedDescription)")
      print("[JikanApiClient] JSON Decoder detailed error:")
      print(error)
      print("[JikanApiClient] API response:")

      if let responseBodyString = String(data: data, encoding: .utf8) {
        print(responseBodyString)
      }
      else {
        print("[JikanApiClient] Unable to convert response body to a string")
      }

      throw ApiClientError.canNotDecodeResponseJson
    }
  }
}
