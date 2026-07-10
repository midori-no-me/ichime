import Anime365Kit
import OSLog

public struct Anime365KitFactory: Sendable {
  // MARK: Properties

  private let anime365BaseURL: Anime365BaseURL
  private let logger: Logger
  private let urlSession: URLSession

  // MARK: Lifecycle

  public init(
    anime365BaseURL: Anime365BaseURL,
    logger: Logger,
    urlSession: URLSession
  ) {
    self.anime365BaseURL = anime365BaseURL
    self.logger = logger
    self.urlSession = urlSession
  }

  // MARK: Functions

  public func createWebClient() async -> Anime365Kit.WebClient {
    .init(
      baseURL: await self.anime365BaseURL.get(),
      logger: self.logger,
      urlSession: self.urlSession
    )
  }

  public func createWebClient(withBaseURL: URL) async -> Anime365Kit.WebClient {
    .init(
      baseURL: withBaseURL,
      logger: self.logger,
      urlSession: self.urlSession
    )
  }

  public func createApiClient() async -> Anime365Kit.ApiClient {
    .init(
      baseURL: await self.anime365BaseURL.get(),
      logger: self.logger,
      urlSession: self.urlSession
    )
  }

  public func baseURL() async -> URL {
    await self.anime365BaseURL.get()
  }
}
