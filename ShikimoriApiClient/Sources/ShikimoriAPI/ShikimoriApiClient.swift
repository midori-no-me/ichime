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

    httpRequest.httpMethod = httpMethod.rawValue

    httpRequest.setValue("application/json", forHTTPHeaderField: "Accept")
    httpRequest.setValue(self.userAgent, forHTTPHeaderField: "User-Agent")

    if let requestBody = requestBody {
      httpRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

      do {
        let requestBodyJson = try JSONEncoder().encode(requestBody)

        httpRequest.httpBody = requestBodyJson
      }
      catch {
        throw ShikimoriApiClientError.canNotEncodeRequestJson
      }
    }

    let (data, httpResponse) = try await URLSession.shared.data(for: httpRequest)

    if let requestUrl = httpRequest.url?.absoluteString,
      let httpResponse = httpResponse as? HTTPURLResponse
    {
      print(
        "[ShikimoriAPIV1Client] API request: \(httpMethod) \(requestUrl) [\(httpResponse.statusCode)]"
      )
    }

    do {
      let jsonDecoder = JSONDecoder()

      jsonDecoder.dateDecodingStrategy = .iso8601WithFractionalSeconds

      let apiResponse = try jsonDecoder.decode(T.self, from: data)

      return apiResponse
    }
    catch {
      print("[ShikimoriAPIV1Client] Decoding JSON error: \(error.localizedDescription)")
      print("[ShikimoriAPIV1Client] JSON Decoder detailed error:")
      print(error)
      print("[ShikimoriAPIV1Client] API response:")

      if let responseBodyString = String(data: data, encoding: .utf8) {
        print(responseBodyString)
      }
      else {
        print("[ShikimoriAPIV1Client] Unable to convert response body to a string")
      }

      throw ShikimoriApiClientError.canNotDecodeResponseJson
    }
  }
}

extension Formatter {
  fileprivate static var customISO8601DateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()

    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    return formatter
  }()
}

extension JSONDecoder.DateDecodingStrategy {
  fileprivate static var iso8601WithFractionalSeconds = custom { decoder in
    let dateString = try decoder.singleValueContainer().decode(String.self)
    let customIsoFormatter = Formatter.customISO8601DateFormatter

    if let date = customIsoFormatter.date(from: dateString) {
      return date
    }

    throw DecodingError.dataCorrupted(
      DecodingError.Context(
        codingPath: decoder.codingPath,
        debugDescription: "Invalid date"
      )
    )
  }
}
