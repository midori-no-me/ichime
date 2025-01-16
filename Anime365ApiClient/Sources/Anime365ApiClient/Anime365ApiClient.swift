import Foundation
import OSLog

let logger: Logger = .init(
  subsystem: Bundle.main.bundleIdentifier ?? "dev.midorinome.ichime",
  category: "Anime365ApiClient"
)

public struct Anime365ApiResponse<T: Decodable>: Decodable {
  let data: T
}

public protocol Anime365ApiRequest {
  associatedtype ResponseType: Decodable

  func getEndpoint() -> String
  func getQueryItems() -> [URLQueryItem]
}

public enum Anime365ApiClientError: Error {
  case invalidData
  case requestFailed
}

public final class Anime365ApiClient {
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

  public func sendApiRequest<T: Anime365ApiRequest>(_ apiRequest: T) async throws -> T.ResponseType {
    // Составляем URL запроса
    var fullURL = self.baseURL.appendingPathComponent("/api" + apiRequest.getEndpoint())
    let queryItems = apiRequest.getQueryItems()

    if !queryItems.isEmpty {
      fullURL.append(queryItems: queryItems.sorted(by: { $0.name < $1.name }))
    }

    var httpRequest = URLRequest(url: fullURL)
    httpRequest.setValue("application/json", forHTTPHeaderField: "Accept")
    httpRequest.setValue(self.userAgent, forHTTPHeaderField: "User-Agent")
    httpRequest.timeoutInterval = 3

    // Логируем заранее сформированный запрос
    if let requestUrl = httpRequest.url?.absoluteString {
      logger.notice("[Anime365ApiClient] Prepared API request: GET \(requestUrl)")
    }

    let maxRetries = 3
    var attempt = 0
    var lastError: Error?

    while attempt < maxRetries {
      attempt += 1
      do {
        // Выполняем запрос
        let (data, httpResponse) = try await urlSession.data(for: httpRequest)

        // Логируем ответ
        if let httpResponse = httpResponse as? HTTPURLResponse {
          logger.notice(
            "[Anime365ApiClient] API response: GET \(httpRequest.url?.absoluteString ?? "") [\(httpResponse.statusCode)]"
          )
        }

        // Пытаемся декодировать ответ
        let apiResponse = try JSONDecoder()
          .decode(Anime365ApiResponse<T.ResponseType>.self, from: data)

        return apiResponse.data
      }
      catch {
        lastError = error
        logger.error(
          "[Anime365ApiClient] Request failed on attempt \(attempt): \(error.localizedDescription, privacy: .public)"
        )

        // Если достигнут лимит попыток — выбрасываем последнюю ошибку
        if attempt == maxRetries {
          logger.error("[Anime365ApiClient] Max retries reached. Failing.")
          throw lastError ?? Anime365ApiClientError.requestFailed
        }

        // Ждём немного перед повторной попыткой (например, 1 секунду)
        try? await Task.sleep(nanoseconds: 1_000_000_000)
      }
    }

    // Если по какой-то причине цикл завершился без возврата данных, выбрасываем ошибку
    throw Anime365ApiClientError.requestFailed
  }
}
