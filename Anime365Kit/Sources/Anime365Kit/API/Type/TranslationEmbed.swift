import Foundation

public struct TranslationEmbed: Sendable, Decodable {
  public struct Stream: Sendable, Decodable {
    public let height: Int
    public let urls: [URL]
  }

  public let stream: [Stream]
  public let subtitlesUrl: String?
  public let subtitlesVttUrl: URL?
}
