public struct PlayerChannel: Hashable, Identifiable, Sendable {
  // MARK: Properties

  public let id: String
  public let name: String

  // MARK: Lifecycle

  public init(id: String, name: String) {
    self.id = id
    self.name = name
  }
}
