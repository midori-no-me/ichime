import Foundation
import SwiftSoup

extension ScraperAPI.Request {
  public struct GetUserRate: ScraperHTMLRequest {
    public typealias ResponseType = ScraperAPI.Types.UserRate

    private let id: Int
    private let fullCheck: Bool

    public init(showId id: Int, fullCheck: Bool = false) {
      self.id = id
      self.fullCheck = fullCheck
    }

    public func getEndpoint() -> String {
      "animelist/edit/\(self.id)"
    }

    public func getQueryItems() -> [URLQueryItem] {
      if self.fullCheck {
        return [.init(name: "mode", value: "mini")]
      }

      return [.init(name: "mode", value: "for_list")]
    }

    public func getFormData() -> [URLQueryItem] {
      []
    }

    public func parseResponse(html: String, baseURL: URL) throws -> ScraperAPI.Types.UserRate {
      let fragment = try? SwiftSoup.parseBodyFragment(html, baseURL.absoluteString)
      guard let fragment else {
        throw ScraperAPI.APIClientError.parseError
      }

      if self.fullCheck,
        let emptyButton = try? fragment.select("form.animelist_mini button[type=submit]").first(),
        let emptyButtonText = try? emptyButton.text(trimAndNormaliseWhitespace: true),
        emptyButtonText == "Добавить в список"
      {
        // Для кейса когда аниме нет в списке
        return .init(score: 0, currentEpisode: 0, status: .deleted, comment: "")
      }

      guard
        let scoreText = try fragment.select("#UsersRates_score option[selected]").first()?.val(),
        let score = Int(scoreText)
      else {
        throw ScraperAPI.APIClientError.parseError
      }

      guard let watchedEpisodes = try fragment.getElementById("UsersRates_episodes")?.val(),
        let watched = Int(watchedEpisodes)
      else {
        throw ScraperAPI.APIClientError.parseError
      }

      guard
        let statusText = try fragment.select("#UsersRates_status option[selected]").first()?.val(),
        let statusParsed = Int(statusText),
        let status = ScraperAPI.Types.UserRateStatus(rawValue: statusParsed)
      else {
        throw ScraperAPI.APIClientError.parseError
      }

      let comment =
        (try? fragment.getElementById("UsersRates_comment")?.text(trimAndNormaliseWhitespace: true))
        ?? ""

      return .init(score: score, currentEpisode: watched, status: status, comment: comment)
    }
  }
}
