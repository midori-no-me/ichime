import Foundation

public struct GetSeriesRequest: Anime365ApiRequest {
  public typealias ResponseType = Anime365ApiSeries

  private let seriesId: Int

  public init(
    seriesId: Int
  ) {
    self.seriesId = seriesId
  }

  public func getEndpoint() -> String {
    "/series/\(self.seriesId)"
  }

  public func getQueryItems() -> [URLQueryItem] {
    []
  }
}
