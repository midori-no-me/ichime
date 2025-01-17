import Foundation

public struct Anime365ApiEpisode: Decodable {
  public let id: Int
  public let episodeFull, episodeInt, episodeTitle: String
  public let episodeType: Anime365ApiEpisodeTypeEnum
  public let firstUploadedDateTime: String
  public let isActive, isFirstUploaded, seriesId: Int
  public let translations: [Anime365ApiTranslation]
}

public enum Anime365ApiEpisodeTypeEnum: String, Codable {
  case bd
  case tv
  case ona
  case ova
  case movie
}
