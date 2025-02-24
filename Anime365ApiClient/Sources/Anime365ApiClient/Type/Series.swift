import Foundation

public struct Titles: Decodable {
  public let ru: String?
  public let romaji: String?
  public let en: String?
}

public struct Series: Decodable {
  public let id: Int
  public let title: String
  public let titles: Titles
  public let posterUrl: URL?
  public let myAnimeListScore: String
  public let season: String
  public let type: SeriesType?
}

public struct SeriesFull: Decodable {
  public struct Genre: Decodable {
    public let id: Int
    public let title: String
  }

  public struct Description: Decodable {
    public let source: String
    public let value: String
  }

  public let id: Int
  public let title: String
  public let posterUrl: URL?
  public let myAnimeListScore: String
  public let myAnimeListId: Int
  public let isAiring: Int
  public let numberOfEpisodes: Int
  public let season: String
  public let type: SeriesType?
  public let titles: Titles
  public let genres: [Genre]?
  public let descriptions: [Description]?
  public let episodes: [Episode]?
}
