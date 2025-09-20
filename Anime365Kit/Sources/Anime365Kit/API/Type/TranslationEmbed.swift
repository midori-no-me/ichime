import Foundation

public struct TranslationEmbed: Decodable {
  public struct Stream: Decodable {
    public let height: Int
    public let urls: [URL]
  }

  public let stream: [Stream]
  public let subtitlesUrl: String?
  public let subtitlesVttUrl: URL?
}
