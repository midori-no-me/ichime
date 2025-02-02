import Foundation

struct EpisodeNumberFormatter: FormatStyle {
  typealias FormatInput = Int

  typealias FormatOutput = String

  func format(_ value: Int) -> String {
    value.formatted(.number)
  }
}
