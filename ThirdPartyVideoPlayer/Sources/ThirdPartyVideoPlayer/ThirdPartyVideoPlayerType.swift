import Foundation

public enum ThirdPartyVideoPlayerType: String, CaseIterable, Identifiable {
  case infuse
  case vlc

  public var id: String {
    self.rawValue
  }

  public var appStoreUrl: URL {
    switch self {
    case .infuse:
      URL(string: "https://apps.apple.com/app/id1136220934")!
    case .vlc:
      URL(string: "https://apps.apple.com/app/id650377962")!
    }
  }

  public var name: String {
    switch self {
    case .infuse:
      "Infuse"
    case .vlc:
      "VLC"
    }
  }

  public var supportsExternalSubtitlesPlayback: Bool {
    switch self {
    case .infuse:
      true
    case .vlc:
      false
    }
  }
}
