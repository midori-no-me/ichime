import Foundation

public struct TranslationEmbed: Sendable, Decodable {
  // MARK: Nested Types

  public struct Stream: Sendable, Decodable {
    public let height: Int
    public let urls: [URL]
  }

  // MARK: Properties

  public let stream: [Stream]
  public let subtitlesUrl: String?
  public let subtitlesVttUrl: URL?
}
