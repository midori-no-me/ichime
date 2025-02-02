import Foundation
import ScraperAPI

struct SubtitlesProxyUrlGenerator {
  private let anime365BaseUrl: URL

  init(
    anime365BaseUrl: URL
  ) {
    self.anime365BaseUrl = anime365BaseUrl
  }

  func generate(translationId: Int) -> URL {
    var components = URLComponents()

    components.scheme = "https"
    components.host = "anime365-subs-proxy-worker.dimensi.workers.dev"
    components.path = "/\(translationId).ass"
    components.queryItems = [
      URLQueryItem(
        name: "domain",
        value: self.anime365BaseUrl.host()!
      ),
      URLQueryItem(
        name: "cookie_token",
        value: "FooBar"
      ),
    ]

    return components.url!
  }
}
