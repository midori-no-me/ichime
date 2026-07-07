import Foundation

public struct VideoQualityNumberFormatter: FormatStyle {
  public typealias FormatInput = Int

  public typealias FormatOutput = String

  public init() {}

  public func format(_ value: Int) -> String {
    "\(value)p"
  }
}
