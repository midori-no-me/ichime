import Foundation

public protocol EpisodeProtocol {
  var id: Int { get }
  var episodeFull: String { get }
  var episodeInt: String { get }
  var episodeType: String { get }
  var firstUploadedDateTime: Date { get }
  var isActive: Int { get }
  var isFirstUploaded: Int { get }
}

public struct Episode: Sendable, Decodable, EpisodeProtocol {
  public let id: Int
  public let episodeFull: String
  public let episodeInt: String
  public let episodeType: String
  public let firstUploadedDateTime: Date
  public let isActive: Int
  public let isFirstUploaded: Int
}

public struct EpisodeFull: Sendable, Decodable, EpisodeProtocol {
  public let id: Int
  public let episodeFull: String
  public let episodeInt: String
  public let episodeType: String
  public let firstUploadedDateTime: Date
  public let isActive: Int
  public let isFirstUploaded: Int
  public let seriesId: Int
  public let translations: [Translation]
}
