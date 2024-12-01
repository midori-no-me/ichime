//
//  ContentProvider.swift
//  TopShelf
//
//  Created by p.flaks on 29.03.2024.
//

import OSLog
import ScraperAPI
import TVServices

let logger = Logger(subsystem: "dev.midorinome.ichime.topshelf", category: "contentProvider")

class ContentProvider: TVTopShelfContentProvider {
  let cookieStorage = HTTPCookieStorage.sharedCookieStorage(
    forGroupContainerIdentifier: ServiceLocator.appGroup
  )
  var session: ScraperAPI.Session {
    .init(cookieStorage: cookieStorage, baseURL: ServiceLocator.websiteBaseUrl)
  }

  var api: ScraperAPI.APIClient {
    .init(
      baseURL: ServiceLocator.websiteBaseUrl,
      userAgent: ServiceLocator.userAgent,
      session: session
    )
  }

  override func loadTopShelfContent(completionHandler: @escaping (TVTopShelfContent?) -> Void) {
    Task {
      do {
        let nextToWatch = try await api.sendAPIRequest(ScraperAPI.Request.GetNextToWatch())

        let schema = ServiceLocator.topShellSchema
        // Reply with a content object.
        let items = nextToWatch.map({
          let item = TVTopShelfSectionedItem(identifier: String($0.id))
          item.title = "\($0.episode.displayName) — \($0.name.romaji)"
          item.setImageURL($0.imageURL, for: .screenScale1x)
          item.setImageURL($0.imageURL, for: .screenScale2x)
          item.imageShape = .poster
          item.playAction = URL(
            string: "\(schema)://episode?id=\($0.episode.id)&title=\($0.episode.displayName)"
          ).map { TVTopShelfAction(url: $0) }
          item.displayAction = URL(string: "\(schema)://show?id=\($0.id)").map {
            TVTopShelfAction(url: $0)
          }
          return item
        })

        let section = TVTopShelfItemCollection(items: items)
        section.title = "Серии к просмотру"
        let sections = [section]

        let content = TVTopShelfSectionedContent(sections: sections)

        completionHandler(content)
      }
      catch {
        print(error)
        completionHandler(nil)
      }
    }
  }
}
