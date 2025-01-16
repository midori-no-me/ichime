import Foundation
import SwiftSoup

extension ScraperAPI.Types {
  /**
     Тип описывает элементы с блока "Серии к просмотру" на главной странице
     - Parameters:
        - id: show id
        - name: название шоу
        - imageURL: постер шоу
        - episode: инфа о эпизоде, внутри есть id эпизода

     */
  public struct WatchShow {
    public let id: Int
    public let name: Name
    public let imageURL: URL
    public let episode: Episode
    public let update: UpdateType

    public enum UpdateType {
      case plan(date: Date)
      case release(date: Date)
      case update(date: Date)

      public var date: Date {
        switch self {
        case let .plan(date):
          return date
        case let .release(date):
          return date
        case let .update(date):
          return date
        }
      }
    }

    init(id: Int, name: Name, imageSrc: URL, episode: Episode, update: UpdateType) {
      self.id = id
      self.name = name
      imageURL = imageSrc
      self.episode = episode
      self.update = update
    }

    init(from htmlElement: Element, baseURL: URL) throws {
      let episodeLink = try htmlElement.getElementsByTag("a").first()?.attr("href") ?? ""

      guard let (showID, episodeID, _) = extractIDs(from: episodeLink) else {
        logger
          .error(
            "\(String(describing: Self.self)): cannot extractIDs from url, \(episodeLink, privacy: .public)"
          )
        throw ScraperAPI.APIClientError.parseError
      }

      let image = try htmlElement.select(".collection-item.avatar .circle").imageBackground()
        .replacingOccurrences(of: ".140x140.1", with: "").dropFirst()
      let episodeNumberText = try htmlElement.select("span.online-h").first()?.text() ?? ""
      let episode = Episode(id: episodeID, episodeText: episodeNumberText)

      let ruName = try Self.extractNameFromHTML(from: htmlElement.select("h5.line-1 a").first())
      let enName = try Self.extractNameFromHTML(from: htmlElement.select("h6.line-2 a").first())
      let name = Name(ru: ruName, romaji: enName)

      let updateInfo = try UpdateType(from: htmlElement.select("span.title").first()?.text() ?? "")

      self.init(
        id: showID,
        name: name,
        imageSrc: baseURL.appending(path: image),
        episode: episode,
        update: updateInfo
      )
    }

    private static func extractNameFromHTML(from element: Element?) -> String {
      guard let element else {
        return ""
      }
      return element.ownText()
    }
  }
}

extension ScraperAPI.Types.WatchShow.UpdateType {
  init(from updateInfo: String) throws {
    let pattern = "\\((.*?)\\)"
    let regex = try NSRegularExpression(pattern: pattern, options: [])
    let matches = regex.matches(
      in: updateInfo,
      options: [],
      range: NSRange(location: 0, length: updateInfo.utf16.count)
    )

    guard let match = matches.first else {
      logger
        .error(
          "\(String(describing: Self.self)): cannot updateInfoRange from text, \(updateInfo, privacy: .public)"
        )
      throw ScraperAPI.APIClientError.parseError
    }

    let updateInfoRange = Range(match.range(at: 1), in: updateInfo)

    guard let updateInfoString = updateInfoRange.map({ String(updateInfo[$0]) })
    else {
      logger
        .error(
          "\(String(describing: Self.self)): cannot updateInfoRange from text, \(updateInfo, privacy: .public)"
        )
      throw ScraperAPI.APIClientError.parseError
    }

    let components = updateInfoString.components(separatedBy: " ")
    guard components.count >= 2, let dateString = components.last,
      let date = Self.parseDate(from: dateString)
    else {
      logger
        .error(
          "\(String(describing: Self.self)): cannot parse date or string from text, \(components, privacy: .public)"
        )
      throw ScraperAPI.APIClientError.parseError
    }

    switch components[0] {
    case "вышла":
      self = .release(date: date)
    case "в":
      self = .plan(date: date)
    case "обновлено":
      self = .update(date: date)
    default:
      logger
        .error(
          "\(String(describing: Self.self)): cannot parse type from text, \(components[0], privacy: .public)"
        )
      throw ScraperAPI.APIClientError.parseError
    }
  }

  private static func parseDate(from dateString: String) -> Date? {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd.MM.yy"

    return dateFormatter.date(from: dateString)
  }
}
