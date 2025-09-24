import Foundation

public enum LoginError: Error {
  case webClientError(WebClientError)
  case invalidCredentials
}

extension WebClient {
  public func login(
    username: String,
    password: String
  ) async throws(LoginError) -> Void {
    var html: String

    do {
      html = try await self.sendRequest(
        "/users/login",
        queryItems: [],
        formData: [
          .init(name: "LoginForm[username]", value: username),
          .init(name: "LoginForm[password]", value: password),
          .init(name: "dynpage", value: "1"),
          .init(name: "yt0", value: ""),
        ],
      )
    }
    catch {
      throw .webClientError(error)
    }

    if html.contains("Неверный E-mail или пароль.") {
      throw .invalidCredentials
    }
  }
}
