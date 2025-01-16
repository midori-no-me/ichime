import Foundation
import SwiftSoup

extension ScraperAPI.Types {
  public struct UserRate {
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

  public enum UserRateStatus: Int, CaseIterable {
    case planned
    case watching
    case completed
    case onHold
    case dropped
    case deleted = 99
  }
}
