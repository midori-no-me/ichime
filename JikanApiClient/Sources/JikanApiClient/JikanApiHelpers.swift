import Foundation

public struct JikanApiHelpers {
  public static func convertApiDateStringToDate(
    _ string: String
  ) -> Date? {
    let newFormatter = ISO8601DateFormatter()

    return newFormatter.date(from: string)
  }
}
