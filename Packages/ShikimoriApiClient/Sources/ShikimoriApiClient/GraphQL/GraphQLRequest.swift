import Foundation

struct AnyEncodable: Encodable, Sendable {
  private let _encode: @Sendable (Encoder) throws -> Void

  public init<T: Encodable & Sendable>(_ value: T) {
    self._encode = { encoder in
      try value.encode(to: encoder)
    }
  }

  public func encode(to encoder: Encoder) throws {
    try self._encode(encoder)
  }
}

struct GraphQLRequest<Variables: Encodable & Sendable>: Sendable, Encodable {
  public let operationName: String
  public let variables: Variables
  public let query: String
}
