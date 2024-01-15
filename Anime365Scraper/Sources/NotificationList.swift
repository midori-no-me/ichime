//
//  File.swift
//
//
//  Created by Nikita Nafranets on 07.01.2024.
//

import Foundation
import SwiftSoup

public extension Anime365Scraper {
    /**
     Структура для запросов к разделу уведомлений
     */
    struct NotificationList {
        private let httpClient: API.HTTPClient
        public init(httpClient: API.HTTPClient) {
            self.httpClient = httpClient
        }

        /**
         Запрос счетчика непрочитанных уведомлений. Если уведомлений нет, то вернется `nil`
         Если сделать запрос  `NotificationList.notifications`, то счетчик обнулится
         */
        public func notificationCount() async -> Int? {
            do {
                let result = try await httpClient.requestHTML(method: .main)
                let doc: Document = try SwiftSoup.parse(result)
                guard let counterElement = try doc.select("[href=/notifications/index]").first(),
                      let match = try counterElement.text().firstMatch(of: #/(?<count>\d+)/#),
                      let counter = Int(match.output.count)
                else {
                    return nil
                }

                return counter
            } catch {
                return nil
            }
        }

        /**
         Возвращает список уведомлений
         */
        public func notifications(page: Int = 1) async -> [Types.Notification] {
            do {
                let parameters: [String: String] = [
                    "Notifications_page": String(page),
                    "ajax": "yw0"
                ]
                let result = try await httpClient.requestHTML(method: .notifications, parameters: parameters)
                let doc: Document = try SwiftSoup.parse(result)
                let notificationsElements = try doc.select("#yw0 .notifications-item")

                return notificationsElements.array().compactMap { Types.Notification(from: $0) }
            } catch {
                return []
            }
        }
    }
}

public extension Anime365Scraper.Types {
    struct Notification {
        public let showID: Int
        public let name: Anime365Scraper.Types.Name
        public let imageSrc: String
        public let episode: Anime365Scraper.Types.Episode
        public let translation: Translation
    }

    struct Translation {
        public let id: Int
        public let type: String
    }
}

extension Anime365Scraper.Types.Notification {
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
            let translation = Anime365Scraper.Types.Translation(id: translationID ?? 0, translationTitle: translationTitle)

            let message = try html.select(".notifications-item__message").text(trimAndNormaliseWhitespace: true)

            let episode = Anime365Scraper.Types.Episode(id: episodeID, episodeText: message)
            let name = Self.parseName(message: message)

            self.init(showID: showID, name: name, imageSrc: imgSrc, episode: episode, translation: translation)
        } catch {
            return nil
        }
    }

    private static func parseName(message: String) -> Anime365Scraper.Types.Name {
        if let match = message.firstMatch(of: #/^(?:Фильм|.*серия\s)(?<title>.+)/#) {
            let titles = match.output.title.components(separatedBy: "/").map { $0.trimmingCharacters(in: .whitespaces) }
            return Anime365Scraper.Types.Name(ru: titles.item(at: 0) ?? "", en: titles.item(at: 1) ?? "")
        }

        return Anime365Scraper.Types.Name(ru: "", en: "")
    }
}

extension Anime365Scraper.Types.Translation {
    init(id: Int, translationTitle: String) {
        let type = String(translationTitle.firstMatch(of: #/\s\((.*)\)/#)?.output.1 ?? "")
        self.init(id: id, type: type)
    }
}
