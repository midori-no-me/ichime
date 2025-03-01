import Foundation

public struct Episode: Decodable {
  public let id: Int
  public let episodeFull: String
  public let episodeInt: String
  public let episodeType: String
  public let firstUploadedDateTime: Date
  public let isActive: Int
  public let isFirstUploaded: Int
}

public struct EpisodeFull: Decodable {
  public let id: Int
  public let episodeFull: String
  public let episodeInt: String
  public let episodeType: String
  public let firstUploadedDateTime: Date
  public let isActive: Int
  public let isFirstUploaded: Int
  public let seriesId: Int
  public let translations: [Translation]

  public var asEpisode: Episode {
    .init(
      id: self.id,
      episodeFull: self.episodeFull,
      episodeInt: self.episodeInt,
      episodeType: self.episodeType,
      firstUploadedDateTime: self.firstUploadedDateTime,
      isActive: self.isActive,
      isFirstUploaded: self.isFirstUploaded
    )
  }
}
