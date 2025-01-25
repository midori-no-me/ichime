import Foundation

public struct Episode: Decodable {
  public let id: Int
  public let episodeFull: String
  public let episodeInt: String
  public let episodeTitle: String
  public let episodeType: EpisodeType
  public let firstUploadedDateTime: Date
  public let isActive: Int
  public let isFirstUploaded: Int
  public let seriesId: Int
  public let translations: [Translation]
}

public enum EpisodeType: String, Codable {
  case bd
  case tv
  case ona
  case ova
  case movie
}
