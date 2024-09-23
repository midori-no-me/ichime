//
//  PlayerPreference.swift
//  ichime
//
//  Created by n.nafranets on 20.09.2024.
//

import Foundation
import SwiftUI

class PlayerPreference: ObservableObject {
  @AppStorage("defaultPlayer") var selectedPlayer: Player = .infuse

  enum Player: String, CaseIterable {
    case iOS
    case infuse
    case VLC
    case SVPlayer

    var supportSubtitle: Bool {
      switch self {
      case .infuse, .VLC:
        return true
      case .iOS, .SVPlayer:
        return false
      }
    }
  }

  private let allowedCharacterSet =
    CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")

  func getLink(type: Player, video: URL, subtitle: URL?) -> URL? {
    switch type {
    case .infuse:
      return getInfuseLink(video: video, subtitle: subtitle)
    case .VLC:
      return getVLCLink(video: video, subtitle: subtitle)
    case .SVPlayer:
      return getSVPlayerLink(video: video, subtitle: subtitle)
    case .iOS:
      return nil
    }
  }

  private func getSVPlayerLink(video: URL, subtitle: URL?) -> URL? {
    let videoURL = video.absoluteString.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)
    var url = "svplayer://x-callback-url/stream?url=\(videoURL ?? "")"
    if let subtitleURL = subtitle?.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
      url += "&sub=\(subtitleURL)"
    }
    return URL(string: url)
  }

  private func getVLCLink(video: URL, subtitle: URL?) -> URL? {
    let videoURL = video.absoluteString.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)

    var url = "vlc-x-callback://x-callback-url/stream?url=\(videoURL ?? "")"
    if let subtitleURL = subtitle?.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
      url += "&sub=\(subtitleURL)"
    }
    return URL(string: url)
  }

  private func getInfuseLink(video: URL, subtitle: URL?) -> URL? {
    let videoURL = video.absoluteString.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)

    var urlString = "infuse://x-callback-url/play?url=\(videoURL ?? "")"

    if let subtitleURL = subtitle?.absoluteString
      .addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)
    {
      urlString += "&sub=\(subtitleURL)"
    }

    return URL(string: urlString)
  }
}
