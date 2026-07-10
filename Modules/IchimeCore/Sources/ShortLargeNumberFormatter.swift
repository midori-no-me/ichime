import Foundation

// periphery:ignore
public struct ShortLargeNumberFormatter: FormatStyle {
  // MARK: Nested Types

  public typealias FormatInput = Int

  public typealias FormatOutput = String

  // MARK: Lifecycle

  public init() {}

  // MARK: Functions

  public func format(_ value: Int) -> String {
    if value < 1000 {
      return "\(value)"
    }
    else if value < 1_000_000 {
      let formatted = Double(value) / 1000

      return formatted.truncatingRemainder(dividingBy: 1) == 0
        ? "\(Int(formatted))K"
        : String(format: "%.1fK", formatted)
    }
    else {
      let formatted = Double(value) / 1_000_000

      return formatted.truncatingRemainder(dividingBy: 1) == 0
        ? "\(Int(formatted))M"
        : String(format: "%.1fM", formatted)
    }
  }
}
