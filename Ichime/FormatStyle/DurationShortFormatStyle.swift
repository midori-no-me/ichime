import Foundation

struct DurationShortFormatStyle: FormatStyle {
  func format(_ value: Duration) -> String {
    let totalSeconds = value.components.seconds
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let seconds = totalSeconds % 60

    if hours > 0 {
      return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
    else {
      return String(format: "%02d:%02d", minutes, seconds)
    }
  }
}
