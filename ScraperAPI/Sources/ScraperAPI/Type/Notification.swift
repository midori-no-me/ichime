//
//  File.swift
//
//
//  Created by Nikita Nafranets on 24.01.2024.
//

import Foundation
import SwiftSoup

public extension ScraperAPI.Types {
    struct Notification {
        public let showID: Int
        public let name: ScraperAPI.Types.Name
        public let imageSrc: String
        public let episode: ScraperAPI.Types.Episode
        public let translation: Translation
    }

    struct Translation {
        public let id: Int
        public let type: String

        init(id: Int, type: String) {
            self.id = id
            self.type = type
        }

        init(id: Int, translationTitle: String) {
            let type = String(translationTitle.firstMatch(of: #/\s\((.*)\)/#)?.output.1 ?? "")
            self.init(id: id, type: type)
        }
    }
}

extension ScraperAPI.Types.Notification {
    init?(from html: Element) {
        do {
            let img = try html.select(".notifications-item__image a")
            let styleAttr = try img.attr("style")
            let imgSrc: String
            if let match = styleAttr.firstMatch(of: #/url\('(.*)'\);/#) {
                imgSrc = String(match.output.1)
            } else {
                imgSrc = ""
            }

            let notificationAnchor = try html.select(".notifications-item__title a")
            let href = try notificationAnchor.attr("href")

            guard let (showID, episodeID, translationID) = extractIDs(from: href) else {
                return nil
            }

            let translationTitle = try notificationAnchor.text(trimAndNormaliseWhitespace: true)
            let translation = ScraperAPI.Types.Translation(id: translationID ?? 0, translationTitle: translationTitle)

            let message = try html.select(".notifications-item__message").text(trimAndNormaliseWhitespace: true)

            let episode = ScraperAPI.Types.Episode(id: episodeID, episodeText: message)
            let name = Self.parseName(message: message)

            self.init(showID: showID, name: name, imageSrc: imgSrc, episode: episode, translation: translation)
        } catch {
            return nil
        }
    }

    private static func parseName(message: String) -> ScraperAPI.Types.Name {
        if let match = message.firstMatch(of: #/^(?:Фильм|.*серия\s)(?<title>.+)/#) {
            let titles = match.output.title.components(separatedBy: "/").map { $0.trimmingCharacters(in: .whitespaces) }
            return ScraperAPI.Types.Name(ru: titles.item(at: 0) ?? "", romaji: titles.item(at: 1) ?? "")
        }

        return ScraperAPI.Types.Name(ru: "", romaji: "")
    }
}
