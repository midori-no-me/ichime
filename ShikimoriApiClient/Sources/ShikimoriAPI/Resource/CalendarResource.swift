extension ShikimoriApiClient {
  public func getCalendar() async throws -> [CalendarEntry] {
    try await sendRequest(
      httpMethod: .GET,
      endpoint: "/api/calendar",
      queryItems: [],
      requestBody: nil
    )
  }
}
