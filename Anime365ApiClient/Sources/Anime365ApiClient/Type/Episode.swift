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
  public let translations: [Translation]
}
