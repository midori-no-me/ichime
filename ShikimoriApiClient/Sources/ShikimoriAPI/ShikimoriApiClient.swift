import Foundation

enum HttpMethod: String {
  case GET
  case POST
  case PATCH
  case PUT
  case DELETE
}

public enum ShikimoriApiClientError: Error {
  case canNotDecodeResponseJson
  case canNotEncodeRequestJson
  case requestFailed
}

public class ShikimoriApiClient {
  private let baseUrl: URL
  private let userAgent: String

  public init(
    baseUrl: URL,
    userAgent: String
  ) {
    self.baseUrl = baseUrl
    self.userAgent = userAgent
  }

  func sendRequest<T: Decodable>(
    httpMethod: HttpMethod,
    endpoint: String,
    queryItems: [URLQueryItem],
    requestBody: Encodable?
  ) async throws -> T {
    var fullURL = baseUrl.appendingPathComponent(endpoint)

    if !queryItems.isEmpty {
      fullURL.append(queryItems: queryItems.sorted(by: { $0.name < $1.name }))
    }

    var httpRequest = URLRequest(url: fullURL)

    httpRequest.httpMethod = httpMethod.rawValue

    httpRequest.setValue("application/json", forHTTPHeaderField: "Accept")
    httpRequest.setValue(userAgent, forHTTPHeaderField: "User-Agent")

    if let requestBody = requestBody {
      httpRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

      do {
        let requestBodyJson = try JSONEncoder().encode(requestBody)

        httpRequest.httpBody = requestBodyJson
      } catch {
        throw ShikimoriApiClientError.canNotEncodeRequestJson
      }
    }

    let (data, httpResponse) = try await URLSession.shared.data(for: httpRequest)

    if let requestUrl = httpRequest.url?.absoluteString, let httpResponse = httpResponse as? HTTPURLResponse {
      print("[ShikimoriAPIV1Client] API request: \(httpMethod) \(requestUrl) [\(httpResponse.statusCode)]")
    }

    do {
      let apiResponse = try JSONDecoder()
        .decode(T.self, from: data)

      return apiResponse
    } catch {
      print("[ShikimoriAPIV1Client] Decoding JSON error: \(error.localizedDescription)")
      print("[ShikimoriAPIV1Client] JSON Decoder detailed error:")
      print(error)
      print("[ShikimoriAPIV1Client] API response:")

      if let responseBodyString = String(data: data, encoding: .utf8) {
        print(responseBodyString)
      } else {
        print("[ShikimoriAPIV1Client] Unable to convert response body to a string")
      }

      throw ShikimoriApiClientError.canNotDecodeResponseJson
    }
  }
}
