extension ApiClient {
  public func getAnimeStaff(
    id: Int
  ) async throws -> [StaffMember] {
    try await sendRequest(
      endpoint: "/anime/\(id)/staff",
      queryItems: []
    )
  }
}
