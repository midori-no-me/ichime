//
//  GetNotifications.swift
//
//
//  Created by Nikita Nafranets on 24.01.2024.
//

import Foundation
import SwiftSoup

public extension ScraperAPI.Request {
    struct GetNotifications: ScraperHTMLRequest {
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
                .init(name: "Notifications_page", value: String(page)),
                .init(name: "ajax", value: "yw0")
            ]
        }
        
        public func getFormData() -> [URLQueryItem] {
            []
        }
        
        public func parseResponse(html: String, baseURL: URL) throws -> [ScraperAPI.Types.Notification] {
            do {
                let doc: Document = try SwiftSoup.parse(html)
                let notificationsElements = try doc.select("#yw0 .notifications-item")
                
                return notificationsElements.array().compactMap { ScraperAPI.Types.Notification(from: $0) }
            } catch {
                logger.error("\(String(describing: GetNotifications.self)): cannot parse, \(error.localizedDescription, privacy: .public)")
                return []
            }
        }
    }
}
