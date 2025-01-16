extension ShikimoriApiClient {
  public func getCalendar() async throws -> [CalendarEntry] {
    try await self.sendRequest(
      httpMethod: .GET,
      endpoint: "/api/calendar",
      queryItems: [],
      requestBody: nil
    )
  }
}
