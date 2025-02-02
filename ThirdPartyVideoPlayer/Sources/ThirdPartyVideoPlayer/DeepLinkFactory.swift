import Foundation

public struct DeepLinkFactory {
  private static let allowedCharacterSet: CharacterSet =
    .init(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")

  public static func buildUniversalLinkUrl(
    externalPlayerType: ThirdPartyVideoPlayerType,
    videoUrl: URL,
    subtitlesUrl: URL?
  ) -> URL {
    switch externalPlayerType {
    case .infuse:
      return Self.getInfuseLink(videoUrl: videoUrl, subtitlesUrl: subtitlesUrl)
    case .vlc:
      return Self.getVlcLink(videoUrl: videoUrl)
    }
  }

  private static func getInfuseLink(
    videoUrl: URL,
    subtitlesUrl: URL?
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
