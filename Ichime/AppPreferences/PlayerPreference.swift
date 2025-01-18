import Foundation
import SwiftUI

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

  private let allowedCharacterSet: CharacterSet =
    .init(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")

  func getLink(type: Player, video: URL, subtitle: URL?) -> URL? {
    switch type {
    case .Infuse:
      return self.getInfuseLink(video: video, subtitle: subtitle)
    case .VLC:
      return self.getVLCLink(video: video, subtitle: subtitle)
    case .SVPlayer:
      return self.getSVPlayerLink(video: video, subtitle: subtitle)
    }
  }

  private func getSVPlayerLink(video: URL, subtitle: URL?) -> URL? {
    let videoURL = video.absoluteString.addingPercentEncoding(
      withAllowedCharacters: self.allowedCharacterSet
    )
    var url = "svplayer://x-callback-url/stream?url=\(videoURL ?? "")"
    if let subtitleURL = subtitle?.absoluteString.addingPercentEncoding(
      withAllowedCharacters: .urlQueryAllowed
    ) {
      url += "&sub=\(subtitleURL)"
    }
    return URL(string: url)
  }

  private func getVLCLink(video: URL, subtitle: URL?) -> URL? {
    let videoURL = video.absoluteString.addingPercentEncoding(
      withAllowedCharacters: self.allowedCharacterSet
    )

    var url = "vlc-x-callback://x-callback-url/stream?url=\(videoURL ?? "")"
    if let subtitleURL = subtitle?.absoluteString.addingPercentEncoding(
      withAllowedCharacters: .urlQueryAllowed
    ) {
      url += "&sub=\(subtitleURL)"
    }
    return URL(string: url)
  }

  private func getInfuseLink(video: URL, subtitle: URL?) -> URL? {
    let videoURL = video.absoluteString.addingPercentEncoding(
      withAllowedCharacters: self.allowedCharacterSet
    )

    var urlString = "infuse://x-callback-url/play?url=\(videoURL ?? "")"

    if let subtitleURL = subtitle?.absoluteString
      .addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)
    {
      urlString += "&sub=\(subtitleURL)"
    }

    return URL(string: urlString)
  }
}
