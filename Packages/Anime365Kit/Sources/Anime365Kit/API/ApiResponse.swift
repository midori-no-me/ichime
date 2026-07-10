import Foundation

struct ApiSuccessfulResponse<T: Decodable>: Decodable {
  let data: T
}

struct ApiErrorResponse: Decodable {
  // MARK: Nested Types

  struct ApiErrorProperties: Decodable {
    public let code: Int
    public let message: String
  }

  // MARK: Properties

  let error: ApiErrorProperties
}
