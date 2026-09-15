import Foundation

struct RestApiDateDecoder {
  // MARK: Lifecycle

  private init() {}

  // MARK: Static Functions

  static func getDateDecodingStrategy() -> JSONDecoder.DateDecodingStrategy {
    .custom { decoder in
      let dateFormatter = ISO8601DateFormatter()
      dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

      let dateString = try decoder.singleValueContainer().decode(String.self)

      if let date = dateFormatter.date(from: dateString) {
        return date
      }

      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription: "Invalid date"
        )
      )
    }
  }
}
