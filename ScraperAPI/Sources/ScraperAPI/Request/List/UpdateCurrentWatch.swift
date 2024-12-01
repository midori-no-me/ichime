//
//  File.swift
//
//
//  Created by Nikita Nafranets on 08.03.2024.
//

import Foundation

extension ScraperAPI.Request {
  public struct UpdateCurrentWatch: ScraperHTMLRequest {
    private let id: Int

    public init(translationId id: Int) {
      self.id = id
    }

    public func getEndpoint() -> String {
      "translations/watched/\(id)"
    }

    public func getQueryItems() -> [URLQueryItem] {
      []
    }

    public func getFormData() -> [URLQueryItem] {
      [.init(name: ScraperAPI.Session.Cookie.csrf.rawValue, value: nil)]
    }

    public func parseResponse(html _: String, baseURL _: URL) throws {}

    public typealias ResponseType = Void
  }
}
