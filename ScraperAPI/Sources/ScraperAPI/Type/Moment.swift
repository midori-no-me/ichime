//
//  File.swift
//
//
//  Created by Nikita Nafranets on 24.03.2024.
//

import Foundation
import SwiftSoup

public extension ScraperAPI.Types {
    struct Moment {
        public let id: Int
        public let title: String
        public let duration: String
        public let animePoster: URL
        public let preview: URL
        public let fromAnime: String
        public let user: User?
        public let date: String
        public let hits: String

        public struct User {
            public let id: Int
            public let name: String
            public let avatar: URL
        }

        init(
            id: Int,
            title: String,
            duration: String,
            animePoster: URL,
            preview: URL,
            fromAnime: String,
            user: User?,
            date: String,
            hits: String
        ) {
            self.id = id
            self.title = title
            self.duration = duration
            self.animePoster = animePoster
            self.preview = preview
            self.fromAnime = fromAnime
            self.user = user
            self.date = date
            self.hits = hits
        }

        init(from element: Element, withUser user: User?, baseURL: URL) throws {
            guard let strId = try? element.select(".m-moment__title a").attr("href").split(separator: "/").last,
                  let id = Int(strId),
                  let title = try? element.select(".m-moment__title a").text(trimAndNormaliseWhitespace: true),
                  let duration = try? element.select(".m-moment__duration.card-title")
                  .text(trimAndNormaliseWhitespace: true),
                  let animePoster = try? element.select(".m-moment__poster.a img").attr("src"),
                  let preview = try? element.select(".m-moment__thumb.a img").attr("src").split(separator: "?").first,
                  let fromAnime = try? element.select(".m-moment__episode").text(trimAndNormaliseWhitespace: true),
                  let date = try? element.select(".m-moment__date").text(trimAndNormaliseWhitespace: true),
                  let hits = try? element.select(".m-moment__views").text(trimAndNormaliseWhitespace: true)
            else {
                throw ScraperAPI.APIClientError.parseError
            }

            self.init(
                id: id,
                title: title,
                duration: duration,
                animePoster: baseURL.appending(path: animePoster),
                preview: baseURL.appending(path: preview),
                fromAnime: fromAnime,
                user: user,
                date: date,
                hits: hits
            )
        }

        init(from element: Element, baseURL: URL) throws {
            if let userName = try? element.select(".m-moment-author-name").text(trimAndNormaliseWhitespace: true),
               let userIdStr = try? element.select(".m-moment-author-name a").attr("href").split(separator: "/")
               .item(at: 1),
               let userId = Int(userIdStr),
               let userAvatar = try? element.select(".circle.m-moment__author_avatar").imageBackground()
            {
                try self.init(
                    from: element,
                    withUser: .init(id: userId, name: userName, avatar: baseURL.appending(path: userAvatar)),
                    baseURL: baseURL
                )
            } else {
                try self.init(from: element, withUser: nil, baseURL: baseURL)
            }
        }
    }

    struct MomentEmbed {
        public let id: Int
        public let title: String
        public let video: [VideoSource]

        public struct VideoSource: Codable {
            public let height: Int
            public let urls: [String]
        }

        init(id: Int, title: String, video: [VideoSource]) {
            self.id = id
            self.title = title
            self.video = video
        }

        init(from element: Element) throws {
            let json = JSONDecoder()
            let videoContainerData = element.dataset()

            guard let id = Int(videoContainerData["id"] ?? ""),
                  let title = videoContainerData["title"],
                  let sourcesData = videoContainerData["sources"]?.data(using: .utf8),
                  let sources = try? json.decode([VideoSource].self, from: sourcesData)
            else {
                throw ScraperAPI.APIClientError.parseError
            }

            self.init(id: id, title: title, video: sources)
        }
    }
}
