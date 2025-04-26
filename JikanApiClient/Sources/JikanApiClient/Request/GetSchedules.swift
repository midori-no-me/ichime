import Foundation

extension ApiClient {
  public func getSchedules(
    filter: ScheduleFilter? = nil,
    page: Int? = nil,
    limit: Int? = nil
  ) async throws -> (data: [Anime], hasMore: Bool) {
    var queryItems: [URLQueryItem] = []

    if let filter {
      queryItems.append(
        URLQueryItem(
          name: "filter",
          value: filter.rawValue
        )
      )
    }

    if let page {
      queryItems.append(
        URLQueryItem(
          name: "page",
          value: String(page)
        )
      )
    }

    if let limit {
      queryItems.append(
        URLQueryItem(
          name: "limit",
          value: String(limit)
        )
      )
    }

    return try await sendRequestWithPagination(
      endpoint: "/schedules",
      queryItems: queryItems
    )
  }
}
