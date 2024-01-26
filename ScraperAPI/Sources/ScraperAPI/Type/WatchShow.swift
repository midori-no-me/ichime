//
//  File.swift
//
//
//  Created by Nikita Nafranets on 24.01.2024.
//

import Foundation
import SwiftSoup

public extension ScraperAPI.Types {
    /**
     Тип описывает элементы с блока "Серии к просмотру" на главной странице
     */
    struct WatchShow {
        public let id: Int
        public let name: Name
        public let episode: Episode
        public let update: Update

        public struct Update {
            public let type: UpdateType
            public let date: Date

            public enum UpdateType {
                case plan
                case release
                case update
            }
        }

        init(id: Int, name: Name, episode: Episode, update: Update) {
            self.id = id
            self.name = name
            self.episode = episode
            self.update = update
        }

        init(from htmlElement: Element) throws {
            let episodeLink = try htmlElement.getElementsByTag("a").first()?.attr("href") ?? ""

            guard let (showID, episodeID, _) = extractIDs(from: episodeLink) else {
                logger.error("\(String(describing: Self.self)): cannot extractIDs from url, \(episodeLink, privacy: .public)")
                throw ScraperAPI.APIClientError.parseError
            }

            let episodeNumberText = try htmlElement.select("span.online-h").first()?.text() ?? ""
            let episode = Episode(id: episodeID, episodeText: episodeNumberText)

            let ruName = try htmlElement.select("h5.line-1 a").first()?.text() ?? ""
            let enName = try htmlElement.select("h6.line-2 a").first()?.text() ?? ""
            let name = Name(ru: ruName, romaji: enName)

            let updateInfo = try Update(from: htmlElement.select("span.title").first()?.text() ?? "")

            self.init(id: showID, name: name, episode: episode, update: updateInfo)
        }
    }
}

extension ScraperAPI.Types.WatchShow.Update {
    init(from updateInfo: String) throws {
        let pattern = "\\((.*?)\\)"
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let matches = regex.matches(in: updateInfo, options: [], range: NSRange(location: 0, length: updateInfo.utf16.count))

        guard let match = matches.first else {
            logger.error("\(String(describing: Self.self)): cannot updateInfoRange from text, \(updateInfo, privacy: .public)")
            throw ScraperAPI.APIClientError.parseError
        }

        let updateInfoRange = Range(match.range(at: 1), in: updateInfo)

        guard let updateInfoString = updateInfoRange.map({ String(updateInfo[$0]) }),
              let parsedData = Self.parseUpdateTypeAndDate(from: updateInfoString)
        else {
            logger.error("\(String(describing: Self.self)): cannot updateInfoRange from text, \(updateInfo, privacy: .public)")
            throw ScraperAPI.APIClientError.parseError
        }

        self.init(type: parsedData.type, date: parsedData.date)
    }

    private static func parseUpdateTypeAndDate(from updateInfo: String) -> (type: UpdateType, date: Date)? {
        let components = updateInfo.components(separatedBy: " ")
        if components.count >= 2, let dateString = components.last, let date = parseDate(from: dateString) {
            switch components[0] {
            case "вышла":
                return (type: .release, date: date)
            case "в":
                return (type: .plan, date: date)
            case "обновлено":
                return (type: .update, date: date)
            default:
                break
            }
        }

        return nil
    }

    private static func parseDate(from dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yy.MM.dd"

        return dateFormatter.date(from: dateString)
    }
}
