import Foundation

extension ScraperAPI.Request {
  public struct UpdateUserRate: ScraperHTMLRequest {
    public typealias ResponseType = ScraperAPI.Types.UserRate

    private let id: Int
    private let params: ScraperAPI.Types.UserRate

    public init(showId id: Int, userRate params: ScraperAPI.Types.UserRate) {
      self.id = id
      self.params = params
    }

    public func getEndpoint() -> String {
      "animelist/edit/\(id)"
    }

    public func getQueryItems() -> [URLQueryItem] {
      [.init(name: "mode", value: "mini")]
    }

    public func getFormData() -> [URLQueryItem] {
      [
        .init(name: "UsersRates[score]", value: String(params.score)),
        .init(name: "UsersRates[episodes]", value: String(params.currentEpisode)),
        .init(name: "UsersRates[status]", value: String(params.status.rawValue)),
        .init(name: "UsersRates[comment]", value: String(params.comment)),
      ]
    }

    public func parseResponse(html: String, baseURL: URL) throws -> ScraperAPI.Types.UserRate {
      params
    }
  }
}
