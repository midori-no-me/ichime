import Foundation

extension WebClient {
  public func updateProfilePlayerChannel(_ playerChannel: PlayerChannel) async throws(WebClientError) -> Void {
    _ = try await self.sendRequest(
      "/users/profile",
      queryItems: [],
      formData: [
        .init(name: "Users[useOtherServers]", value: playerChannel.id)
      ]
    )
  }
}
