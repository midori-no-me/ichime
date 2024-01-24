//
//  Extensions.swift
//
//
//  Created by Nikita Nafranets on 24.01.2024.
//

import Foundation
import OSLog

let logger = Logger(subsystem: Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? "dev.ani365", category: "ScaperAPI")

extension Array {
    func item(at index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

func extractIDs(from url: String) -> (showID: Int, episodeID: Int, translationID: Int?)? {
    let pattern = #/\/catalog\/(?:.*?)-(?<showID>\d+)\/(?:.*?)-(?<episodeID>\d+)(?:\/(?:.*?)-(?<translationID>\d+))?/#

    if let match = url.firstMatch(of: pattern) {
        if let showID = Int(match.output.showID), let episodeID = Int(match.output.episodeID) {
            if let translationIDString = match.output.translationID {
                return (showID, episodeID, Int(translationIDString))
            }
            return (showID, episodeID, nil)
        }
    }

    return nil
}
