import Anime365Kit
import OSLog

struct Anime365KitFactory: Sendable {
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

  func createWebClient() async -> Anime365Kit.WebClient {
    .init(
      baseURL: await self.anime365BaseURL.get(),
      userAgent: self.userAgent,
      logger: self.logger,
      urlSession: self.urlSession
    )
  }

  func createApiClient() async -> Anime365Kit.ApiClient {
    .init(
      baseURL: await self.anime365BaseURL.get(),
      userAgent: self.userAgent,
      logger: self.logger,
      urlSession: self.urlSession
    )
  }

  func baseURL() async -> URL {
    await self.anime365BaseURL.get()
  }
}
