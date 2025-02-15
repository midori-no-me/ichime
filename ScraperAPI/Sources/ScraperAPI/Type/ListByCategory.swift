import Foundation
import SwiftSoup

extension ScraperAPI.Types {
  /**
     Секция которую получаем в результаты парсинга страницы "Мой список".
     Хранит в себе список шоу, а так же тип блока: "Смотрю", "Брошено" и т.д.
     */
  public struct ListByCategory {
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

  public enum ListCategoryType: String, CaseIterable, Hashable {
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
  public struct Show: Identifiable {
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
      }
      else {
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
