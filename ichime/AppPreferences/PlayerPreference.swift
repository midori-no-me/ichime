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
    }
    
    private let allowedCharacterSet =
    CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")
    
    func getLink(type: Player, video: URL, subtitle: URL?) -> URL? {
        switch type {
        case .infuse:
            return getInfuseLink(video: video, subtitle: subtitle)
        case .VLC:
            return getVLCLink(video: video)
        case .iOS:
            return nil
        }
    }
    
    private func getVLCLink(video: URL) -> URL? {
        let videoURL = video.absoluteString.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet)
        
        return URL(string: "vlc-x-callback://x-callback-url/ACTION?url=\(videoURL ?? "")")
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
