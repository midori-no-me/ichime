import OSLog
import ScraperAPI
import ShikimoriApiClient
import TVServices

class ContentProvider: TVTopShelfContentProvider {
  let cookieStorage: HTTPCookieStorage = .sharedCookieStorage(
    forGroupContainerIdentifier: ServiceLocator.appGroup
  )

  var session: ScraperAPI.Session {
    .init(cookieStorage: self.cookieStorage, baseURL: ServiceLocator.websiteBaseUrl)
  }

  var scraperApiClient: ScraperAPI.APIClient {
    .init(
      baseURL: ServiceLocator.websiteBaseUrl,
      userAgent: ServiceLocator.userAgent,
      session: self.session
    )
  }

  var shikimoriApiClient: ShikimoriApiClient.ApiClient {
    .init(
      baseUrl: ServiceLocator.shikimoriBaseUrl,
      userAgent: ServiceLocator.shikimoriUserAgent,
      logger: Logger(subsystem: ServiceLocator.applicationId, category: "ShikimoriApiClient")
    )
  }

  var showReleaseSchedule: ShowReleaseSchedule {
    .init(
      shikimoriApiClient: self.shikimoriApiClient
    )
  }

  var currentlyWatchingService: CurrentlyWatchingService {
    .init(
      scraperApi: self.scraperApiClient
    )
  }

  override func loadTopShelfContent(completionHandler: @escaping (TVTopShelfContent?) -> Void) {
    Task {
      async let currentlyWatchingSectionFuture = self.getCurrentlyWatchingSection()
      async let calendarSectionsFuture = self.getCalendarSection()

      let currentlyWatchingSection = await currentlyWatchingSectionFuture
      let calendarSections = await calendarSectionsFuture

      let content = TVTopShelfSectionedContent(sections: [currentlyWatchingSection] + calendarSections)

      completionHandler(content)
    }
  }

  private func getCurrentlyWatchingSection() async -> TVTopShelfItemCollection<TVTopShelfSectionedItem> {
    let episodes = (try? await currentlyWatchingService.getEpisodesToWatch(page: 1)) ?? []

    let topShelfItems = episodes.map {
      let topShelfItem = TVTopShelfSectionedItem(identifier: String($0.episodeId))

      topShelfItem.title = "\($0.episodeTitle) — \(self.romajiShowTitle($0.showName))"
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

  private func getCalendarSection() async -> [TVTopShelfItemCollection<TVTopShelfSectionedItem>] {
    let scheduleDays = (try? await showReleaseSchedule.getSchedule()) ?? []

    let sections: [TVTopShelfItemCollection<TVTopShelfSectionedItem>] = scheduleDays.map { scheduleDay in
      let topShelfItems = scheduleDay.shows.map {
        let topShelfItem = TVTopShelfSectionedItem(identifier: String($0.id))

        topShelfItem.title = "\(formatTime($0.nextEpisodeReleaseDate)) — \($0.title.translated.japaneseRomaji)"
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

  private func romajiShowTitle(_ showName: ShowName) -> String {
    if let parsedShowName = showName as? ParsedShowName {
      return parsedShowName.romaji
    }

    return showName.getFullName()
  }
}
