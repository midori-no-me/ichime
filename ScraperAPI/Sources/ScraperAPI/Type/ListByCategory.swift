//
//  ListByCategory.swift
//
//
//  Created by Nikita Nafranets on 24.01.2024.
//

import Foundation
import SwiftSoup

public extension ScraperAPI.Types {
    /**
     Секция которую получаем в результаты парсинга страницы "Мой список".
     Хранит в себе список шоу, а так же тип блока: "Смотрю", "Брошено" и т.д.
     */
    struct ListByCategory {
        public let type: ListCategoryType
        public let shows: [Show]

        init(type: ListCategoryType, shows: [Show]) {
            self.type = type
            self.shows = shows
        }

        init(from section: Element) throws {
            let title = try section.select(".card-title").text(trimAndNormaliseWhitespace: true)

            guard let type = ListCategoryType(rawValue: title) else {
                logger
                    .error(
                        "\(String(describing: Self.self)): cannot get category name from text, \(title, privacy: .public)"
                    )
                throw ScraperAPI.APIClientError.parseError
            }

            try self.init(from: section, type: type)
        }

        init(from section: Element, type: ListCategoryType) throws {
            let titles = try section.select(".m-animelist-item")
            let shows = try titles.array().compactMap { try Show(from: $0) }
            self.init(type: type, shows: shows)
        }
    }

    enum ListCategoryType: String, CaseIterable, Hashable {
        case watching = "Смотрю"
        case completed = "Просмотрено"
        case onHold = "Отложено"
        case dropped = "Брошено"
        case planned = "Запланировано"
    }

    /**
     Тип который получается в результати парсинга страницы "Мой список"
     В типе есть id серия, его название, сколько эпизодов посмотрели и всего и оценка пользователя
     */
    struct Show: Identifiable {
        public let id: Int
        public let name: Name
        public let episodes: (watched: Int, total: Int?)
        public let score: Int?

        init(id: Int, name: Name, episodes: (watched: Int, total: Int?), score: Int?) {
            self.id = id
            self.name = name
            self.episodes = episodes
            self.score = score
        }

        init(from item: Element) throws {
            let id = try Int(item.attr("data-id")) ?? 0

            let fullTitle = try item.select("a").text().components(separatedBy: " / ")
                .map { $0.trimmingCharacters(in: .whitespaces) }

            let name: Name
            if fullTitle.count == 2 {
                name = Name(ru: fullTitle.item(at: 0) ?? "", romaji: fullTitle.item(at: 1) ?? "")
            } else {
                name = Name(ru: fullTitle.joined(separator: " / "), romaji: "")
            }

            let episodes = try item.select("[data-name=episodes]").text().components(separatedBy: "/")
                .map { $0.trimmingCharacters(in: .whitespaces) }
            let episodesWatched = Int(episodes.item(at: 0) ?? "") ?? 0
            let totalEpisodes = Int(episodes.item(at: 1) ?? "") ?? nil

            let score = try Int(item.select("[data-name=score]").text())

            self.init(id: id, name: name, episodes: (episodesWatched, totalEpisodes), score: score)
        }
    }
}

public extension ScraperAPI.Types.Show {
    static let sampleData = ScraperAPI.Types.Show(
        id: 21587,
        name: ScraperAPI.Types.Name(ru: "Благословение небожителей", romaji: "Tian Guan Ci Fu"),
        episodes: (watched: 3, total: 11),
        score: nil
    )
}

public extension ScraperAPI.Types.ListByCategory {
    static let sampleData = [ScraperAPI.Types.ListByCategory(
        type: ScraperAPI.Types.ListCategoryType.watching,
        shows: [ScraperAPI.Types.Show(
            id: 21587,
            name: ScraperAPI.Types.Name(ru: "Благословение небожителей", romaji: "Tian Guan Ci Fu"),
            episodes: (watched: 3, total: 11),
            score: nil
        ), ScraperAPI.Types.Show(
            id: 8762,
            name: ScraperAPI.Types.Name(ru: "Ван-Пис", romaji: "One Piece TV"),
            episodes: (watched: 1091, total: 9_223_372_036_854_775_807),
            score: Optional(10)
        ), ScraperAPI.Types.Show(
            id: 33263,
            name: ScraperAPI.Types
                .Name(ru: "Злодейка девяносто девятого уровня: «Я босс, но не король демонов»",
                      romaji: "Akuyaku Reijou Level 99: Watashi wa Ura-Boss desu ga Maou dewa Arimasen"),
            episodes: (watched: 3, total: 12),
            score: nil
        ), ScraperAPI.Types.Show(
            id: 34488,
            name: ScraperAPI.Types
                .Name(
                    ru: "Злодейка наслаждается своей седьмой жизнью в качестве свободолюбивой невесты во вражеской стране",
                    romaji: "Loop 7-kaime no Akuyaku Reijou wa, Moto Tekikoku de Jiyuu Kimama na Hanayome Seikatsu wo Mankitsu suru"
                ),
            episodes: (watched: 2, total: 12),
            score: nil
        ), ScraperAPI.Types.Show(
            id: 33109,
            name: ScraperAPI.Types.Name(ru: "Исюра", romaji: "Ishura"),
            episodes: (watched: 3, total: 12),
            score: nil
        ), ScraperAPI.Types.Show(
            id: 25582,
            name: ScraperAPI.Types
                .Name(ru: "Лунное путешествие приведёт к новому миру 2 сезон",
                      romaji: "Tsuki ga Michibiku Isekai Douchuu 2nd Season"),
            episodes: (watched: 3, total: 25),
            score: nil
        ), ScraperAPI.Types.Show(
            id: 33130,
            name: ScraperAPI.Types.Name(ru: "Монолог фармацевта", romaji: "Kusuriya no Hitorigoto"),
            episodes: (watched: 15, total: 24),
            score: nil
        ), ScraperAPI.Types.Show(
            id: 26142,
            name: ScraperAPI.Types.Name(ru: "Нежеланно бессмертный авантюрист", romaji: "Nozomanu Fushi no Boukensha"),
            episodes: (watched: 3, total: 12),
            score: nil
        ), ScraperAPI.Types.Show(
            id: 30001,
            name: ScraperAPI.Types.Name(ru: "Нежить и Неудача", romaji: "Undead Unluck"),
            episodes: (watched: 13, total: 24),
            score: nil
        ), ScraperAPI.Types.Show(
            id: 33267,
            name: ScraperAPI.Types
                .Name(ru: "Несносные пришельцы 2 сезон (2022)", romaji: "Urusei Yatsura (2022) 2nd Season"),
            episodes: (watched: 1, total: 23),
            score: nil
        ), ScraperAPI.Types.Show(
            id: 28344,
            name: ScraperAPI.Types.Name(ru: "Поднятие уровня в одиночку", romaji: "Ore dake Level Up na Ken"),
            episodes: (watched: 3, total: 12),
            score: nil
        ), ScraperAPI.Types.Show(
            id: 30414,
            name: ScraperAPI.Types.Name(ru: "Провожающая в последний путь Фрирен", romaji: "Sousou no Frieren"),
            episodes: (watched: 19, total: 28),
            score: nil
        ), ScraperAPI.Types.Show(
            id: 26084,
            name: ScraperAPI.Types.Name(ru: "Рагна Багровый", romaji: "Ragna Crimson"),
            episodes: (watched: 14, total: 24),
            score: nil
        ), ScraperAPI.Types.Show(
            id: 28240,
            name: ScraperAPI.Types
                .Name(ru: "Рубеж Шангри-Ла: Любитель игрошлака бросает вызов топ-игре",
                      romaji: "Shangri-La Frontier: Kusoge Hunter, Kamige ni Idoman to su"),
            episodes: (watched: 15, total: 25),
            score: nil
        ), ScraperAPI.Types.Show(
            id: 28275,
            name: ScraperAPI.Types.Name(ru: "Сасаки и Пи", romaji: "Sasaki to Pii-chan"),
            episodes: (watched: 3, total: 12),
            score: nil
        ), ScraperAPI.Types.Show(
            id: 33201,
            name: ScraperAPI.Types.Name(ru: "Становясь волшебницей", romaji: "Mahou Shoujo ni Akogarete"),
            episodes: (watched: 4, total: 13),
            score: nil
        ), ScraperAPI.Types.Show(
            id: 2973,
            name: ScraperAPI.Types.Name(ru: "Судьба/Ночь схватки", romaji: "Fate Stay Night"),
            episodes: (watched: 1, total: 24),
            score: nil
        ), ScraperAPI.Types.Show(
            id: 24145,
            name: ScraperAPI.Types.Name(ru: "Убийца гоблинов 2 сезон", romaji: "Goblin Slayer II"),
            episodes: (watched: 7, total: 12),
            score: nil
        )]
    )]
}
