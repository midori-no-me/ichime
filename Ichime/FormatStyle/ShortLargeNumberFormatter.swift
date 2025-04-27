import Foundation

struct ShortLargeNumberFormatter: FormatStyle {
  typealias FormatInput = Int

  typealias FormatOutput = String

  func format(_ value: Int) -> String {
    if value < 1000 {
      return "\(value)"
    }
    else if value < 1_000_000 {
      let formatted = Double(value) / 1000

      return formatted.truncatingRemainder(dividingBy: 1) == 0
        ? "\(Int(formatted))k"
        : String(format: "%.1fk", formatted)
    }
    else {
      let formatted = Double(value) / 1_000_000

      return formatted.truncatingRemainder(dividingBy: 1) == 0
        ? "\(Int(formatted))M"
        : String(format: "%.1fM", formatted)
    }
  }
}
