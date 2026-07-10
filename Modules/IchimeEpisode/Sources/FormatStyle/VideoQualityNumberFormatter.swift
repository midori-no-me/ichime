import Foundation

public struct VideoQualityNumberFormatter: FormatStyle {
  // MARK: Nested Types

  public typealias FormatInput = Int

  public typealias FormatOutput = String

  // MARK: Lifecycle

  public init() {}

  // MARK: Functions

  public func format(_ value: Int) -> String {
    "\(value)p"
  }
}
