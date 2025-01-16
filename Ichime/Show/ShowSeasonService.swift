import Foundation

public enum CalendarSeason: String {
  case winter
  case spring
  case summer
  case autumn

  func getLocalizedTranslation() -> String {
    switch self {
    case .winter:
      "Зима"
    case .spring:
      "Весна"
    case .summer:
      "Лето"
    case .autumn:
      "Осень"
    }
  }

  func getApiName() -> String {
    switch self {
    case .winter:
      "winter"
    case .spring:
      "spring"
    case .summer:
      "summer"
    case .autumn:
      "autumn"
    }
  }
}

public struct AiringSeason {
  public let calendarSeason: CalendarSeason
  public let year: Int

  init(
    calendarSeason: CalendarSeason,
    year: Int
  ) {
    self.calendarSeason = calendarSeason
    self.year = year
  }

  init?(fromTranslatedString: String) {
    if fromTranslatedString.isEmpty {
      return nil
    }

    let stringParts = fromTranslatedString.split(separator: " ", maxSplits: 2)

    if stringParts.count != 2 {
      return nil
    }

    let translatedCalendarSeason = stringParts[0]
    let yearString = stringParts[1]

    let calendarSeason: CalendarSeason? =
      switch translatedCalendarSeason {
      case "Зима":
        .winter
      case "Весна":
        .spring
      case "Лето":
        .summer
      case "Осень":
        .autumn
      default:
        nil
      }

    guard let calendarSeason else {
      return nil
    }

    let year = Int(yearString)

    guard let year else {
      return nil
    }

    if year < 1900 {
      return nil
    }

    self.calendarSeason = calendarSeason
    self.year = year
  }

  func getLocalizedTranslation() -> String {
    "\(calendarSeason.getLocalizedTranslation()) \(year)"
  }
}

struct ShowSeasonService {
  public static let NEXT_SEASON = 1
  public static let CURRENT_SEASON = 0
  public static let PREVIOUS_SEASON = -1

  private let currentDate: Date

  init() {
    currentDate = Date()
  }

  /// 1 = next season
  /// 0 = current season
  /// -1 = previous season
  func getRelativeSeason(shift: Int) -> AiringSeason {
    let shiftedDate = Calendar.current.date(byAdding: .month, value: shift * 3, to: currentDate)!
    let shiftedYear = Calendar.current.component(.year, from: shiftedDate)
    let shiftedMonthNumber = Calendar.current.component(.month, from: shiftedDate)

    return switch shiftedMonthNumber {
    case 1, 2, 3:  // January, February, March
      AiringSeason(calendarSeason: CalendarSeason.winter, year: shiftedYear)
    case 4, 5, 6:  // April, May, June
      AiringSeason(calendarSeason: CalendarSeason.spring, year: shiftedYear)
    case 7, 8, 9:  // July, August, September
      AiringSeason(calendarSeason: CalendarSeason.summer, year: shiftedYear)
    default:  // October, November, December
      AiringSeason(calendarSeason: CalendarSeason.autumn, year: shiftedYear)
    }
  }
}
