//
//  UserRate.swift
//
//
//  Created by Nikita Nafranets on 25.01.2024.
//

import Foundation
import SwiftSoup

public extension ScraperAPI.Types {
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

    enum UserRateStatus: Int,  CaseIterable {
        case planned
        case watching
        case completed
        case onHold
        case dropped
        case deleted = 99
    }
}
