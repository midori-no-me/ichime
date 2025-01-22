import Foundation

public struct ListEpisodesRequest: Anime365ApiRequest {
  public typealias ResponseType = [Anime365ApiSeries.EpisodePreview]

  private let seriesId: Int

  public init(
    seriesId: Int
  ) {
    self.seriesId = seriesId
  }

  public func getEndpoint() -> String {
    "/episodes"
  }

  public func getQueryItems() -> [URLQueryItem] {
    let queryItems: [URLQueryItem] = [
      URLQueryItem(
        name: "seriesId",
        value: String(self.seriesId)
      )
    ]

    return queryItems
  }
}
