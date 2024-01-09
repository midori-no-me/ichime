//
//  File.swift
//
//
//  Created by Nikita Nafranets on 10.01.2024.
//

import Foundation

public extension Anime365Scraper {
    enum AuthManager {
        private static let cookieName = "aaaa8ed0da05b797653c4bd51877d861"
        public static func getCookie() -> String? {
            if let cookies = HTTPCookieStorage.shared.cookies,
               let targetCookie = cookies.first(where: { $0.name == cookieName })
            {
                return "\(targetCookie.name)=\(targetCookie.value)"
            }
            return nil
        }
    }
}
