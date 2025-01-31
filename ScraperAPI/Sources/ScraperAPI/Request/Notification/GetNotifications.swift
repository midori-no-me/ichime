import Foundation
import SwiftSoup

extension ScraperAPI.Request {
  public struct GetNotifications: ScraperHTMLRequest {
    public typealias ResponseType = [ScraperAPI.Types.Notification]

    private let page: Int

    public init(page: Int = 1) {
      self.page = page
    }

    public func getEndpoint() -> String {
      "notifications/index"
    }

    public func getQueryItems() -> [URLQueryItem] {
      [
        .init(name: "Notifications_page", value: String(self.page)),
        .init(name: "ajax", value: "yw0"),
      ]
    }

    public func getFormData() -> [URLQueryItem] {
      []
    }

    public func parseResponse(html: String, baseURL: URL) throws -> [ScraperAPI.Types.Notification] {
      do {
        let doc: Document = try SwiftSoup.parse(html)
        let notificationsElements = try doc.select("#yw0 .notifications-item")

        return notificationsElements.array()
          .compactMap { ScraperAPI.Types.Notification(from: $0, baseURL: baseURL) }
      }
      catch {
        logger
          .error(
            "\(String(describing: Self.self)): cannot parse, \(error.localizedDescription, privacy: .public)"
          )
        return []
      }
    }
  }
}
