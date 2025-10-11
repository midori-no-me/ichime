import Foundation
import OSLog

public struct WebClient: Sendable {
  private static let COOKIE_NAME_CSRF = "csrf"
  private static let FORM_DATA_FIELD_CSRF = "csrf"

  let baseURL: URL

  let logger: Logger

  private let urlSession: URLSession

  public init(
    baseURL: URL,
    logger: Logger,
    urlSession: URLSession
  ) {
    self.baseURL = baseURL
    self.urlSession = urlSession
    self.logger = logger
  }

  func sendRequest(
    _ path: String,
    queryItems: [URLQueryItem]
  ) async throws(WebClientError) -> String {
    var fullURL = self.baseURL.appendingPathComponent(path)

    if !queryItems.isEmpty {
      fullURL.append(queryItems: queryItems.sorted(by: { $0.name < $1.name }))
    }

    var httpRequest = URLRequest(url: fullURL)

    httpRequest.timeoutInterval = 10
    httpRequest.httpMethod = "GET"

    httpRequest.setValue("text/html", forHTTPHeaderField: "Accept")

    var data: Data
    var urlResponse: URLResponse

    do {
      (data, urlResponse) = try await self.urlSession.data(for: httpRequest)
    }
    catch {
      self.logger.debug("Error after sending \(URLSession.self) request: \(error)")
      throw .unknownError(error)
    }

    guard let httpResponse = urlResponse as? HTTPURLResponse else {
      self.logger.debug("Could not convert \(URLResponse.self) to \(HTTPURLResponse.self)")
      throw .couldNotConvertResponseToHttpResponse
    }

    self.logger.debug("Web request: \(httpRequest.httpMethod!) \(httpRequest.url!) [\(httpResponse.statusCode)]")

    if httpResponse.statusCode >= 400 {
      self.logger.debug("Bad status code: \(httpResponse.statusCode)")
      throw .badStatusCode
    }

    guard let html = String(data: data, encoding: .utf8) else {
      self.logger.debug("Could not convert HTTP response \(Data.self) to \(String.self)")
      throw .couldNotConvertResponseDataToString
    }

    return html
  }

  func sendRequest(
    _ path: String,
    queryItems: [URLQueryItem],
    formData: [URLQueryItem]
  ) async throws(WebClientError) -> String {
    var fullURL = self.baseURL.appendingPathComponent(path)

    if !queryItems.isEmpty {
      fullURL.append(queryItems: queryItems.sorted(by: { $0.name < $1.name }))
    }

    var httpRequest = URLRequest(url: fullURL)

    httpRequest.timeoutInterval = 10
    httpRequest.httpMethod = "POST"

    httpRequest.setValue("text/html", forHTTPHeaderField: "Accept")
    httpRequest.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")

    var formDataComponents = URLComponents()
    formDataComponents.queryItems = formData

    let csrfTokenFromCookie = self.urlSession.configuration.httpCookieStorage?.cookies(for: fullURL)?.first(where: {
      $0.name == Self.COOKIE_NAME_CSRF
    })
    let randomCsrfToken = UUID().uuidString

    if let csrfTokenFromCookie {
      formDataComponents.queryItems?.append(.init(name: Self.FORM_DATA_FIELD_CSRF, value: csrfTokenFromCookie.value))
    }
    else {
      if let cookie = HTTPCookie(properties: [
        .name: Self.COOKIE_NAME_CSRF,
        .value: randomCsrfToken,
        .domain: self.baseURL.host()!,
        .path: "/",
      ]) {
        self.urlSession.configuration.httpCookieStorage?.setCookie(cookie)
        formDataComponents.queryItems?.append(.init(name: Self.FORM_DATA_FIELD_CSRF, value: randomCsrfToken))
      }
    }

    httpRequest.httpBody = formDataComponents.query?.data(using: .utf8)

    var data: Data
    var urlResponse: URLResponse

    do {
      (data, urlResponse) = try await self.urlSession.data(for: httpRequest)
    }
    catch {
      self.logger.debug("Error after sending \(URLSession.self) request: \(error)")
      throw .unknownError(error)
    }

    guard let httpResponse = urlResponse as? HTTPURLResponse else {
      self.logger.debug("Could not convert \(URLResponse.self) to \(HTTPURLResponse.self)")
      throw .couldNotConvertResponseToHttpResponse
    }

    self.logger.debug("Web request: \(httpRequest.httpMethod!) \(httpRequest.url!) [\(httpResponse.statusCode)]")

    if httpResponse.statusCode >= 400 {
      self.logger.debug("Bad status code: \(httpResponse.statusCode)")
      self.logger.debug("Request headers: \(httpRequest.allHTTPHeaderFields?.debugDescription ?? "")")
      self.logger.debug("Form data: \(formDataComponents.queryItems?.debugDescription ?? "")")
      throw .badStatusCode
    }

    guard let html = String(data: data, encoding: .utf8) else {
      self.logger.debug("Could not convert HTTP response \(Data.self) to \(String.self)")
      throw .couldNotConvertResponseDataToString
    }

    return html
  }

  func logNormalizationError<T>(of dto: T.Type, message: String) -> Void {
    self.logger.error("Error while normalizing \(dto.self): \(message)")
  }
}
