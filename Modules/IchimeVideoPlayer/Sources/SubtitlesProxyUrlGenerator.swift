import Foundation

public struct SubtitlesProxyURLGenerator: Sendable {
  private let anime365BaseURL: URL

  public init(
    anime365BaseURL: URL
  ) {
    self.anime365BaseURL = anime365BaseURL
  }

  public func generate(translationID: Int) -> URL {
    var components = URLComponents()

    components.scheme = "https"
    components.host = "anime365-subs-proxy-worker.dimensi.workers.dev"
    components.path = "/\(translationID).ass"
    components.queryItems = [
      URLQueryItem(
        name: "domain",
        value: self.anime365BaseURL.host()!
      ),
      URLQueryItem(
        name: "cookie_token",
        value: "FooBar"
      ),
    ]

    return components.url!
  }
}
