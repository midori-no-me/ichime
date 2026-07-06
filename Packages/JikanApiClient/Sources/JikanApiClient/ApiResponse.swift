import Foundation

struct ApiResponse<T: Decodable>: Decodable {
  struct Pagination: Decodable {
    let has_next_page: Bool
  }

  let data: T
  let pagination: Pagination?
}
