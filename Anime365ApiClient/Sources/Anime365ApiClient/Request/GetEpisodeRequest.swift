import Foundation

public struct GetEpisodeRequest: Anime365ApiRequest {
  public typealias ResponseType = Anime365ApiEpisode

  private let episodeId: Int

  public init(
    episodeId: Int
  ) {
    self.episodeId = episodeId
  }

  public func getEndpoint() -> String {
    "/episodes/\(episodeId)"
  }

  public func getQueryItems() -> [URLQueryItem] {
    []
  }
}
