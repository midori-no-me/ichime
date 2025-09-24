import Foundation

struct ApiSuccessfulResponse<T: Decodable>: Decodable {
  let data: T
}

struct ApiErrorResponse: Decodable {
  struct ApiErrorProperties: Decodable {
    public let code: Int
    public let message: String
  }

  let error: ApiErrorProperties
}
