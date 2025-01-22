import Foundation

struct JikanApiResponse<T: Decodable>: Decodable {
  let data: T
}
