import Foundation

extension ApiClient {
  public func getCalendar(censored: Bool? = nil) async throws -> [CalendarEntry] {
    var queryItems: [URLQueryItem] = []

    if let censored {
      queryItems.append(.init(name: "censored", value: censored ? "true" : "false"))
    }

    return try await sendRequest(
      httpMethod: .GET,
      endpoint: "/api/calendar",
      queryItems: queryItems,
      requestBody: nil
    )
  }
}
