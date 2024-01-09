//
//  UserList.swift
//
//
//  Created by Nikita Nafranets on 07.01.2024.
//
import Foundation
import SwiftSoup

public extension Anime365Scraper {
    /**
     Структура для запросов пользовательских списков аниме
     */
    struct UserList {
        private let httpClient: API.HTTPClient
        public init(httpClient: API.HTTPClient) {
            self.httpClient = httpClient
        }

        /**
         Запрос списка "Серии к просмотру"
         */
        public func nextToWatch(page: Int? = nil) async throws -> [Types.WatchShow] {
            let parameters: [String: Any] = [
                "ajax": "m-index-personal-episodes" as Any,
                "pageP": page as Any,
            ].compactMapValues { $0 }
            let result = try await httpClient.requestHTML(url: httpClient.appendURL("/"), parameters: parameters)
            let doc: Document = try SwiftSoup.parse(result, httpClient.baseURL)
            guard let watchSection = try doc.getElementById("m-index-personal-episodes") else { return [] }
            let elements = try watchSection.select("div.m-new-episode")

            return elements.array().compactMap { Types.WatchShow(from: $0) }
        }

        /**
         Запрос пользовательского списка сохраненных аниме
         */
        public func watchList(_ type: Types.UserListCategoryType? = nil) async throws -> [Types.UserListCategory] {
            var url: String = httpClient.appendURL("/users/\(httpClient.userID.value)/list")

            switch type {
            case .completed:
                url = url + "/completed"
            case .dropped:
                url = url + "/dropped"
            case .onHold:
                url = url + "/onhold"
            case .watching:
                url = url + "/watching"
            case .planned:
                url = url + "/planned"
            case .none:
                break
            }

            let parameters: [String: Any] = [
                "dynpage": 1 as Any,
            ]

            let result = try await httpClient.requestHTML(url: url, parameters: parameters)
            let doc = try SwiftSoup.parseBodyFragment(result, httpClient.baseURL)

            let sections = try doc.select(".m-animelist-card")

            if let type, sections.size() == 1 {
                return sections.array().compactMap { Types.UserListCategory(from: $0, type: type) }
            }

            return sections.array().compactMap { Types.UserListCategory(from: $0) }
        }
    }
}

public extension Anime365Scraper.Types {
    /**
     Тип описывает элементы с блока "Серии к просмотру" на главной странице
     */
    struct WatchShow {
        public let id: Int
        public let name: Name
        public let episode: Episode
        public let update: Update
    }

    // MARK: - Episode

    struct Episode {
        public let id: Int
        public let type: EpisodeType
        public let episodeNumber: Double
    }

    enum EpisodeType: String {
        case TV
        case Movie
        case OVA
        case ONA
    }

    // MARK: - Name

    struct Name {
        public let ru, en: String
    }

    // MARK: - Update

    struct Update {
        public let type: UpdateType
        public let date: Date

        public enum UpdateType {
            case plan
            case release
            case update
        }
    }

    /**
     Тип который получается в результати парсинга страницы "Мой список"
     В типе есть id серия, его название, сколько эпизодов посмотрели и всего и оценка пользователя
     */
    struct Show {
        public let id: Int
        public let name: Name
        public let episodes: (watched: Int, total: Int)
        public let score: Int?
    }

    /**
     Секция которую получаем в результаты парсинга страницы "Мой список".
     Хранит в себе список шоу, а так же тип блока: "Смотрю", "Брошено" и т.д.
     */
    struct UserListCategory {
        public let type: UserListCategoryType
        public let shows: [Show]
    }

    enum UserListCategoryType: String {
        case watching = "Смотрю"
        case completed = "Просмотрено"
        case onHold = "Отложено"
        case dropped = "Брошено"
        case planned = "Запланировано"
    }
}

extension Anime365Scraper.Types.WatchShow {
    init?(from htmlElement: Element) {
        do {
            let episodeLink = try htmlElement.getElementsByTag("a").first()?.attr("href") ?? ""
            guard let (showID, episodeID, _) = extractIDs(from: episodeLink) else { return nil }

            // Извлекаем данные из элемента
            let episodeNumberText = try htmlElement.select("span.online-h").first()?.text() ?? ""
            let episode = Anime365Scraper.Types.Episode(id: episodeID, episodeText: episodeNumberText)

            let name = try Anime365Scraper.Types.Name(ru: htmlElement.select("h5.line-1 a").first()?.text() ?? "", en: htmlElement.select("h6.line-2 a").first()?.text() ?? "")
            let updateInfo = try Anime365Scraper.Types.Update(from: htmlElement.select("span.title").first()?.text() ?? "")
            self.init(id: showID, name: name, episode: episode, update: updateInfo)
        } catch {
            return nil
        }
    }
}

extension Anime365Scraper.Types.Episode {
    init(id: Int, episodeText: String) {
        let episodeMeta = Self.extractEpisodeInfo(from: episodeText)
        self.init(id: id, type: episodeMeta.type, episodeNumber: episodeMeta.number)
    }

    private static func extractEpisodeInfo(from input: String) -> (type: Anime365Scraper.Types.EpisodeType, number: Double) {
        // Паттерн для поиска типа эпизода и номера
        let pattern = #/^(OVA|Фильм|ONA)?\s?(\d+\.?\d?)?(?:\sсерия)?/#

        if let match = input.firstMatch(of: pattern) {
            let typeString = match.output.1 ?? ""
            let type: Anime365Scraper.Types.EpisodeType
            switch typeString.lowercased() {
            case "ova":
                type = .OVA
            case "фильм":
                type = .Movie
            case "ona":
                type = .ONA
            case "tv":
                fallthrough
            default:
                type = .TV
            }

            let episodeNumber = Double(match.output.2 ?? "") ?? 0
            return (type, episodeNumber)
        }

        // По умолчанию, если не удалось извлечь значения, возвращаем TV и 0
        return (.TV, 0)
    }
}

extension Anime365Scraper.Types.Update {
    init(from updateInfo: String) {
        if let info = Self.parseUpdateInfo(from: updateInfo) {
            self.init(type: info.type, date: info.date)
        } else {
            self.init(type: .update, date: Date())
        }
    }

    private static func parseUpdateInfo(from input: String) -> (type: UpdateType, date: Date)? {
        let pattern = "\\((.*?)\\)"

        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let matches = regex.matches(in: input, options: [], range: NSRange(location: 0, length: input.utf16.count))

            if let match = matches.first {
                let updateInfoRange = Range(match.range(at: 1), in: input)
                if let updateInfoString = updateInfoRange.map({ String(input[$0]) }) {
                    return parseUpdateTypeAndDate(from: updateInfoString)
                }
            }
        } catch {
            print("Error creating regular expression: \(error)")
        }

        return nil
    }

    private static func parseUpdateTypeAndDate(from updateInfo: String) -> (type: UpdateType, date: Date)? {
        let components = updateInfo.components(separatedBy: " ")
        if components.count >= 2 {
            let dateString = components.last ?? ""

            if let date = parseDate(from: dateString) {
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
        }

        return nil
    }

    private static func parseDate(from dateString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yy.MM.dd"

        return dateFormatter.date(from: dateString)
    }
}

extension Anime365Scraper.Types.UserListCategory {
    init?(from section: Element) {
        do {
            let title = try section.select(".card-title").text(trimAndNormaliseWhitespace: true)

            guard let type = Anime365Scraper.Types.UserListCategoryType(rawValue: title) else { return nil }

            self.init(from: section, type: type)
        } catch {
            return nil
        }
    }

    init?(from section: Element, type: Anime365Scraper.Types.UserListCategoryType) {
        do {
            let titles = try section.select(".m-animelist-item")
            let shows: [Anime365Scraper.Types.Show] = titles.array().compactMap { Anime365Scraper.Types.Show(from: $0) }
            self.init(type: type, shows: shows)
        } catch {
            return nil
        }
    }
}

extension Anime365Scraper.Types.Show {
    init?(from item: Element) {
        do {
            let id = try Int(item.attr("data-id")) ?? 0

            let fullTitle = try item.select("a").text().components(separatedBy: "/").map { $0.trimmingCharacters(in: .whitespaces) }

            let name = Anime365Scraper.Types.Name(ru: fullTitle.item(at: 0) ?? "", en: fullTitle.item(at: 1) ?? "")

            let episodes = try item.select("[data-name=episodes]").text().components(separatedBy: "/").map { $0.trimmingCharacters(in: .whitespaces) }
            let episodesWatched = Int(episodes.item(at: 0) ?? "") ?? 0
            let totalEpisodes = Int(episodes.item(at: 1) ?? "") ?? Int.max

            let score = try Int(item.select("[data-name=score]").text())
            self.init(id: id, name: name, episodes: (episodesWatched, totalEpisodes), score: score)
        } catch {
            return nil
        }
    }
}

extension Array {
    func item(at index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
