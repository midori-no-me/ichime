//
//  CalendarResource.swift
//  ShikimoriApiClient
//
//  Created by Flaks Petr on 24.11.2024.
//

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
