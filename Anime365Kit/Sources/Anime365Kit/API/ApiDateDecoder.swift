import Foundation

public struct ApiDateDecoder {
  /// Если даты нет, вместо пустых строк или `null` Anime 365 API возвращает дату `"2000-01-01 00:00:00"`.
  /// С помощью этого метода можно узнать, является ли дата именно этой датой-пустышкой.
  public static func isEmptyDate(_ date: Date) -> Bool {
    let dateFormatter = Self.getDateFormatter()

    return dateFormatter.string(from: date) == "2000-01-01 00:00:00"
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

  private static func getDateFormatter() -> DateFormatter {
    let dateFormatter = DateFormatter()

    dateFormatter.timeZone = .init(identifier: "MSK")  // API отвечает в московской таймзоне
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

    return dateFormatter
  }
}
