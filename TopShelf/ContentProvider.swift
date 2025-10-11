import OSLog
import ShikimoriApiClient
import TVServices

final class ContentProvider: TVTopShelfContentProvider {
  private static var anime365BaseURL: Anime365BaseURL {
    .init()
  }

  private static var urlSession: URLSession {
    let urlSessionConfig = URLSessionConfiguration.default
    urlSessionConfig.httpCookieStorage = .sharedCookieStorage(forGroupContainerIdentifier: ServiceLocator.appGroup)
    urlSessionConfig.httpAdditionalHeaders?["User-Agent"] = ServiceLocator.userAgent

    return .init(configuration: urlSessionConfig)
  }

  private static var anime365KitFactory: Anime365KitFactory {
    .init(
      anime365BaseURL: self.anime365BaseURL,
      logger: Logger(subsystem: ServiceLocator.applicationId, category: "Anime365Kit"),
      urlSession: urlSession
    )
  }

  private static var shikimoriApiClient: ShikimoriApiClient.ApiClient {
    .init(
      baseUrl: ServiceLocator.shikimoriBaseUrl,
      urlSession: Self.urlSession,
      logger: Logger(subsystem: ServiceLocator.applicationId, category: "ShikimoriApiClient")
    )
  }

  private static var showReleaseSchedule: ShowReleaseSchedule {
    .init(
      shikimoriApiClient: self.shikimoriApiClient
    )
  }

  private static var currentlyWatchingService: CurrentlyWatchingService {
    .init(
      anime365KitFactory: self.anime365KitFactory
    )
  }

  override func loadTopShelfContent(completionHandler: @escaping @Sendable ((any TVTopShelfContent)?) -> Void) {
    Task { @MainActor in
      async let calendarSectionsFuture = Self.getCalendarSection()
      async let currentlyWatchingSectionFuture = Self.getCurrentlyWatchingSection()

      let currentlyWatchingSection = await currentlyWatchingSectionFuture
      let calendarSections = await calendarSectionsFuture

      var sections: [TVTopShelfItemCollection<TVTopShelfSectionedItem>] = []

      if !currentlyWatchingSection.items.isEmpty {
        sections.append(currentlyWatchingSection)
      }

      if !calendarSections.isEmpty {
        sections += calendarSections
      }

      let content = TVTopShelfSectionedContent(sections: sections)

      completionHandler(content)
    }
  }

  private static func getCurrentlyWatchingSection() async -> TVTopShelfItemCollection<TVTopShelfSectionedItem> {
    let episodes = (try? await Self.currentlyWatchingService.getEpisodesToWatch(page: 1)) ?? []

    let topShelfItems = episodes.map {
      let topShelfItem = TVTopShelfSectionedItem(identifier: String($0.episodeId))

      topShelfItem.title = "\($0.episodeTitle) — \($0.showName.getRomajiOrFullName())"
      topShelfItem.setImageURL($0.coverUrl, for: .screenScale1x)
      topShelfItem.setImageURL($0.coverUrl, for: .screenScale2x)
      topShelfItem.imageShape = .poster

      var components = URLComponents()

      components.scheme = "ichime"
      components.host = "episode"
      components.queryItems = [
        URLQueryItem(
          name: "id",
          value: String($0.episodeId)
        )
      ]

      topShelfItem.displayAction = .init(url: components.url!)
      topShelfItem.playAction = .init(url: components.url!)

      return topShelfItem
    }

    let section = TVTopShelfItemCollection(items: topShelfItems)
    section.title = "Серии к просмотру"

    return section
  }

  private static func getCalendarSection() async -> [TVTopShelfItemCollection<TVTopShelfSectionedItem>] {
    let scheduleDays = await Self.showReleaseSchedule.getSchedule()

    let sections: [TVTopShelfItemCollection<TVTopShelfSectionedItem>] = scheduleDays.map { scheduleDay in
      let topShelfItems = scheduleDay.shows.map {
        let topShelfItem = TVTopShelfSectionedItem(identifier: String($0.id))

        topShelfItem.title = "\(formatTime($0.nextEpisodeReleaseDate)) — \($0.title.getRomajiOrFullName())"
        topShelfItem.setImageURL($0.posterUrl, for: .screenScale1x)
        topShelfItem.setImageURL($0.posterUrl, for: .screenScale2x)
        topShelfItem.imageShape = .poster

        var components = URLComponents()

        components.scheme = "ichime"
        components.host = "showByMyAnimeListId"
        components.queryItems = [
          URLQueryItem(
            name: "id",
            value: String($0.id)
          )
        ]

        topShelfItem.displayAction = .init(url: components.url!)
        topShelfItem.playAction = .init(url: components.url!)

        return topShelfItem
      }

      let section = TVTopShelfItemCollection(items: topShelfItems)
      section.title = formatRelativeDateWithWeekdayNameAndDate(scheduleDay.date)

      return section
    }

    return sections
  }
}
