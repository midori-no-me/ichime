import Foundation

public struct ShowProperties: Sendable {
  // MARK: Properties

  public let name: String
  public let seasonNumber: Int?
  public let episodeNumber: Int?

  // MARK: Lifecycle

  public init(name: String, seasonNumber: Int?, episodeNumber: Int?) {
    self.name = name
    self.seasonNumber = seasonNumber
    self.episodeNumber = episodeNumber
  }
}

public struct DeepLinkFactory {
  // MARK: Static Properties

  private static let allowedCharacterSet: CharacterSet =
    .init(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")

  // MARK: Static Functions

  public static func buildUniversalLinkURL(
    externalPlayerType: ThirdPartyVideoPlayerType,
    videoURL: URL,
    subtitlesURL: URL?,
    show: ShowProperties?,
  ) -> URL {
    switch externalPlayerType {
    case .infuse:
      return Self.getInfuseLink(videoURL: videoURL, subtitlesURL: subtitlesURL, show: show)
    case .vlc:
      return Self.getVlcLink(videoURL: videoURL)
    }
  }

  private static func getInfuseLink(
    videoURL: URL,
    subtitlesURL: URL?,
    show: ShowProperties?,
  ) -> URL {
    var components = URLComponents()

    components.scheme = "infuse"
    components.host = "x-callback-url"
    components.path = "/play"
    components.percentEncodedQueryItems = [
      URLQueryItem(
        name: "url",
        value: videoURL.absoluteString.addingPercentEncoding(
          withAllowedCharacters: Self.allowedCharacterSet
        )
      )
    ]

    if let subtitlesURL {
      components.percentEncodedQueryItems?.append(
        URLQueryItem(
          name: "sub",
          value: subtitlesURL.absoluteString.addingPercentEncoding(
            withAllowedCharacters: Self.allowedCharacterSet
          )
        )
      )
    }

    if let show {
      var fileName = "\(show.name) S\(String(format: "%02d", show.seasonNumber ?? 1))"

      if let episodeNumber = show.episodeNumber {
        fileName += " E\(String(format: "%02d", episodeNumber))"
      }

      // According to Infuse docs these characters are invalid: https://support.firecore.com/hc/en-us/articles/215090947-Metadata-101
      let invalidCharacters = #"[\\/:|<>*?"]+"#

      fileName =
        fileName
        .replacingOccurrences(of: invalidCharacters, with: " ", options: .regularExpression)
        .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)

      components.percentEncodedQueryItems?.append(
        URLQueryItem(
          name: "filename",
          value: "\(fileName).mp4".addingPercentEncoding(
            withAllowedCharacters: Self.allowedCharacterSet
          )
        )
      )
    }

    return components.url!
  }

  private static func getVlcLink(
    videoURL: URL
  ) -> URL {
    var components = URLComponents()

    components.scheme = "vlc-x-callback"
    components.host = "x-callback-url"
    components.path = "/stream"
    components.percentEncodedQueryItems = [
      URLQueryItem(
        name: "url",
        value: videoURL.absoluteString.addingPercentEncoding(
          withAllowedCharacters: Self.allowedCharacterSet
        )
      )
    ]

    return components.url!
  }
}
