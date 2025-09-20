import Anime365Kit
import OSLog

struct Anime365KitFactory {
  private let anime365BaseURL: Anime365BaseURL
  private let userAgent: String
  private let logger: Logger
  private let urlSession: URLSession

  init(
    anime365BaseURL: Anime365BaseURL,
    userAgent: String,
    logger: Logger,
    urlSession: URLSession
  ) {
    self.anime365BaseURL = anime365BaseURL
    self.userAgent = userAgent
    self.logger = logger
    self.urlSession = urlSession
  }

  func createWebClient() -> Anime365Kit.WebClient {
    .init(
      baseURL: self.anime365BaseURL.get(),
      userAgent: self.userAgent,
      logger: self.logger,
      urlSession: self.urlSession
    )
  }

  func createApiClient() -> Anime365Kit.ApiClient {
    .init(
      baseURL: self.anime365BaseURL.get(),
      userAgent: self.userAgent,
      logger: self.logger,
      urlSession: self.urlSession
    )
  }

  func baseURL() -> URL {
    self.anime365BaseURL.get()
  }
}
