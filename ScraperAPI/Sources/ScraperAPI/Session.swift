import Foundation

extension ScraperAPI {
  public struct Session {
    public let cookieStorage: HTTPCookieStorage
    public let domain: String
    public init(cookieStorage: HTTPCookieStorage, baseURL domain: URL) {
      self.cookieStorage = cookieStorage
      self.domain = domain.host() ?? "anime365.ru"
    }

    public enum Cookie: String {
      case csrf
      case phpsessid = "PHPSESSID"
      case token = "aaaa8ed0da05b797653c4bd51877d861"
      case guestId
      case fv
      case lastTranslationType
    }

    public func set(name: Cookie, value: String) {
      if let cookie = HTTPCookie(properties: [
        .name: name.rawValue,
        .value: value,
        .domain: domain,
        .path: "/",
      ]) {
        self.cookieStorage.setCookie(
          cookie
        )
      }
    }

    func get(name: Cookie) -> HTTPCookie? {
      self.cookieStorage.cookies?.first(where: { $0.name == name.rawValue })
    }

    public func logout() {
      let cookies = [
        Cookie.csrf.rawValue,
        Cookie.phpsessid.rawValue,
        Cookie.token.rawValue,
        Cookie.guestId.rawValue,
        Cookie.fv.rawValue,
        Cookie.lastTranslationType.rawValue,
      ]
      self.cookieStorage.cookies?.filter { cookie in cookies.contains(where: { cookie.name == $0 }) }
        .forEach {
          self.cookieStorage.deleteCookie($0)
        }
    }
  }
}
