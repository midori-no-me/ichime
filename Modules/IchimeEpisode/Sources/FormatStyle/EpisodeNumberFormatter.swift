import Foundation

public struct EpisodeNumberFormatter: FormatStyle {
  public typealias FormatInput = Int

  public typealias FormatOutput = String

  public init() {}

  public func format(_ value: Int) -> String {
    value.formatted(.number)
  }
}
