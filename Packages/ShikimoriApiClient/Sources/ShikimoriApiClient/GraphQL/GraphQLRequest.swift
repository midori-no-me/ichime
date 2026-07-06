import Foundation

struct AnyEncodable: Encodable, Sendable {
  private let _encode: @Sendable (Encoder) throws -> Void

  init<T: Encodable & Sendable>(_ value: T) {
    self._encode = { encoder in
      try value.encode(to: encoder)
    }
  }

  func encode(to encoder: Encoder) throws {
    try self._encode(encoder)
  }
}

struct GraphQLRequest<Variables: Encodable & Sendable>: Sendable, Encodable {
  enum CodingKeys: String, CodingKey {
    case operationName
    case variables
    case query
  }

  let operationName: String
  let variables: Variables
  let query: String

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    try container.encode(self.operationName, forKey: .operationName)
    try container.encode(self.variables, forKey: .variables)
    try container.encode(self.query, forKey: .query)
  }
}
