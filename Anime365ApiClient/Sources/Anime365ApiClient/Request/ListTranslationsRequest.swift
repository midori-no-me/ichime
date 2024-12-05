import Foundation

public struct ListTranslationsRequest: Anime365ApiRequest {
  public typealias ResponseType = [Anime365ApiTranslation]

  private let episodeId: Int?
  private let seriesId: Int?
  private let limit: Int?
  private let offset: Int?

  public init(
    episodeId: Int? = nil,
    seriesId: Int? = nil,
    limit: Int? = nil,
    offset: Int? = nil
  ) {
    self.episodeId = episodeId
    self.seriesId = seriesId
    self.limit = limit
    self.offset = offset
  }

  public func getEndpoint() -> String {
    "/translations"
  }

  public func getQueryItems() -> [URLQueryItem] {
    var queryItems: [URLQueryItem] = []

    if let episodeId {
      queryItems.append(
        URLQueryItem(
          name: "episodeId",
          value: String(episodeId)
        )
      )
    }

    if let seriesId {
      queryItems.append(
        URLQueryItem(
          name: "seriesId",
          value: String(seriesId)
        )
      )
    }

    if let limit {
      queryItems.append(
        URLQueryItem(
          name: "limit",
          value: String(limit)
        )
      )
    }

    if let offset {
      queryItems.append(
        URLQueryItem(
          name: "offset",
          value: String(offset)
        )
      )
    }

    return queryItems
  }
}
