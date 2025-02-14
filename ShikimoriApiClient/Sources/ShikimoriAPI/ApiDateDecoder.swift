import Foundation

public struct ApiDateDecoder {
  public static func getDateWithoutTimeFormatter() -> DateFormatter {
    let dateFormatter = DateFormatter()

    dateFormatter.dateFormat = "yyyy-MM-dd"

    return dateFormatter
  }

  static func getDateDecodingStrategy() -> JSONDecoder.DateDecodingStrategy {
    .custom { decoder in
      let dateFormatter = Self.getDateFormatter()

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

  private static func getDateFormatter() -> ISO8601DateFormatter {
    let dateFormatter = ISO8601DateFormatter()

    dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    return dateFormatter
  }
}
