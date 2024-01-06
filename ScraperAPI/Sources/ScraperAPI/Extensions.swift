//
//  Extensions.swift
//
//
//  Created by Nikita Nafranets on 24.01.2024.
//

import Foundation
import OSLog

let logger = Logger(
    subsystem: Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String ?? "dev.midorinome.ichime",
    category: "ScaperAPI"
)

extension Array {
    func item(at index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

func getId(from string: String) -> Int {
    let regexp = #/(\d+)$/#
    guard let match = string.firstMatch(of: regexp), let id = Int(match.output.0) else {
        return 0
    }

    return id
}

func extractIDs(from url: String) -> (showID: Int, episodeID: Int, translationID: Int?)? {
    // Отбрасываем query
    guard let withoutQuery = url.components(separatedBy: "?").first else {
        return nil
    }
    // отбрасываем начальный слеш, а потом catalog
    let components = withoutQuery.dropFirst().components(separatedBy: "/").dropFirst()
    let ids = components.map { getId(from: $0) }
    return (showID: ids[0], episodeID: ids[1], translationID: ids.item(at: 2))
}
