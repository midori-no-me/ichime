//
//  File.swift
//
//
//  Created by Nikita Nafranets on 24.01.2024.
//

import Foundation

public extension ScraperAPI.Request {
    struct UpdateWatchList: ScraperHTMLRequest {
        public typealias ResponseType = UserRate

        private let showId: Int
        private let params: UserRate

        init(showId: Int, userRate params: UserRate) {
            self.showId = showId
            self.params = params
        }

        public func getEndpoint() -> String {
            "animelist/edit/\(showId)"
        }

        public func getQueryItems() -> [URLQueryItem] {
            []
        }

        public func getFormData() -> [String: String]? {
            ["UsersRates[score]": String(params.score),
             "UsersRates[episodes]": String(params.currentEpisode),
             "UsersRates[status]": String(params.status.rawValue),
             "UsersRates[comment]": String(params.comment)]
        }

        public func parseResponse(html: String, baseURL: URL) throws -> ScraperAPI.Request.UserRate {
            params
        }
    }

    struct UserRate {
        public let score: Int
        public let currentEpisode: Int
        public let status: UserRateStatus
        public let comment: String

        public init(score: Int, currentEpisode: Int, status: UserRateStatus, comment: String) {
            self.score = score
            self.currentEpisode = currentEpisode
            self.status = status
            self.comment = comment
        }
    }

    enum UserRateStatus: Int {
        case planned
        case watching
        case completed
        case onHold
        case dropped
        case deleted = 99
    }
}
