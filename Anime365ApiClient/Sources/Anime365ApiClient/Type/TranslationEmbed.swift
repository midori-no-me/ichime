public struct TranslationEmbed: Decodable {
  public struct Download: Decodable {
    public let height: Int
    public let url: String
  }

  public struct Stream: Decodable {
    public let height: Int
    public let urls: [String]
  }

  public let embedUrl: String
  public let download: [Download]
  public let stream: [Stream]
  public let subtitlesUrl: String?
  public let subtitlesVttUrl: String?
}
