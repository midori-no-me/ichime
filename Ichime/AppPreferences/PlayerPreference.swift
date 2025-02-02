import Foundation
import SwiftUI
import ThirdPartyVideoPlayer

class PlayerPreference: ObservableObject {
  enum Player: String, CaseIterable {
    case Infuse
    case VLC
    case SVPlayer

    var supportSubtitle: Bool {
      switch self {
      case .Infuse, .VLC:
        return true
      case .SVPlayer:
        return false
      }
    }
  }

  @AppStorage("defaultPlayer") var selectedPlayer: Player = .Infuse

  func getLink(type: Player, video: URL, subtitle: URL?) -> URL? {
    DeepLinkFactory.buildUniversalLinkUrl(
      externalPlayerType: .infuse,
      videoUrl: video,
      subtitlesUrl: subtitle
    )
  }
}
