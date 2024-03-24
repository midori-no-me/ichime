//
//  Extensions.swift
//
//
//  Created by Nikita Nafranets on 24.01.2024.
//

import Foundation
import OSLog
import SwiftSoup

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


extension Elements {
    // background-image: url('/posters/26142.5187294764.140x140.1.jpg'); -> /posters/26142.5187294764.140x140.1.jpg
    func imageBackground() throws -> String {
        let styleAttr = try attr("style")
        guard let matchedText = styleAttr.firstMatch(of: #/url\('(.*)'\);/#)?.output.1 else {
            return ""
        }

        return String(matchedText)
    }
}
