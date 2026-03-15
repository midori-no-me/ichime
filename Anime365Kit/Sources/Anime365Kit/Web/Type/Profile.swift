import Foundation

public struct Profile: Sendable {
  public let id: Int
  public let name: String
  public let avatarURL: URL
  public let channel: StreamingChannel
}
