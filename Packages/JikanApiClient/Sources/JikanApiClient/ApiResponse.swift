import Foundation

struct ApiResponse<T: Decodable>: Decodable {
  let data: T
}
