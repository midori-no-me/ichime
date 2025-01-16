import Foundation
import SwiftSoup

extension ScraperAPI.Request {
  public struct Login: ScraperHTMLRequest {
    public typealias ResponseType = ScraperAPI.Types.User

    private let username: String
    private let password: String

    public init(username: String, password: String) {
      self.username = username
      self.password = password
    }

    public func getEndpoint() -> String {
      "users/login"
    }

    public func getQueryItems() -> [URLQueryItem] {
      []
    }

    public func getFormData() -> [URLQueryItem] {
      [
        .init(name: "LoginForm[username]", value: username),
        .init(name: "LoginForm[password]", value: password),
        .init(name: "dynpage", value: "1"),
        .init(name: "yt0", value: ""),
      ]
    }

    public func parseResponse(html: String, baseURL: URL) throws -> ScraperAPI.Types.User {
      if html.contains(#/Неверный E-mail или пароль/#) {
        logger.error("\(html)")
        throw ScraperAPI.APIClientError.invalidCredentials
      }

      guard let document = try? SwiftSoup.parseBodyFragment(html),
        let content = try? document.select("content").first()
      else {
        logger.error("\(String(describing: Login.self)): cannot parse document")
        throw ScraperAPI.APIClientError.parseError
      }

      guard let user = try? ScraperAPI.Types.User(from: content, baseURL: baseURL) else {
        logger.error("\(String(describing: Login.self)): cannot parse user")
        throw ScraperAPI.APIClientError.parseError
      }

      return user
    }
  }
}
