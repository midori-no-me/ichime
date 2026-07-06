import Foundation

public struct ShowProperties: Sendable {
  public let name: String
  public let seasonNumber: Int?
  public let episodeNumber: Int?

  public init(name: String, seasonNumber: Int?, episodeNumber: Int?) {
    self.name = name
    self.seasonNumber = seasonNumber
    self.episodeNumber = episodeNumber
  }
}

public struct DeepLinkFactory {
  private static let allowedCharacterSet: CharacterSet =
    .init(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")

  public static func buildUniversalLinkUrl(
    externalPlayerType: ThirdPartyVideoPlayerType,
    videoUrl: URL,
    subtitlesUrl: URL?,
    show: ShowProperties?,
  ) -> URL {
    switch externalPlayerType {
    case .infuse:
      return Self.getInfuseLink(videoUrl: videoUrl, subtitlesUrl: subtitlesUrl, show: show)
    case .vlc:
      return Self.getVlcLink(videoUrl: videoUrl)
    }
  }

  private static func getInfuseLink(
    videoUrl: URL,
    subtitlesUrl: URL?,
    show: ShowProperties?,
  ) -> URL {
    var components = URLComponents()

    components.scheme = "infuse"
    components.host = "x-callback-url"
    components.path = "/play"
    components.percentEncodedQueryItems = [
      URLQueryItem(
        name: "url",
        value: videoUrl.absoluteString.addingPercentEncoding(
          withAllowedCharacters: Self.allowedCharacterSet
        )
      )
    ]

    if let subtitlesUrl {
      components.percentEncodedQueryItems?.append(
        URLQueryItem(
          name: "sub",
          value: subtitlesUrl.absoluteString.addingPercentEncoding(
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
    videoUrl: URL
  ) -> URL {
    var components = URLComponents()

    components.scheme = "vlc-x-callback"
    components.host = "x-callback-url"
    components.path = "/stream"
    components.percentEncodedQueryItems = [
      URLQueryItem(
        name: "url",
        value: videoUrl.absoluteString.addingPercentEncoding(
          withAllowedCharacters: Self.allowedCharacterSet
        )
      )
    ]

    return components.url!
  }
}
