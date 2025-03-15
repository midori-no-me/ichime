import Foundation

struct VideoQualityNumberFormatter: FormatStyle {
  typealias FormatInput = Int

  typealias FormatOutput = String

  func format(_ value: Int) -> String {
    "\(value)p"
  }
}
