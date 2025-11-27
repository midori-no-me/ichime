import Foundation
import JikanApiClient

enum CalendarSeason: String, Comparable {
  case winter
  case spring
  case summer
  case autumn

  var orderedValue: Int {
    switch self {
    case .winter:
      return 0
    case .spring:
      return 1
    case .summer:
      return 2
    case .autumn:
      return 3
    }
  }

  static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.orderedValue < rhs.orderedValue
  }

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

  func getAnime365ApiName() -> String {
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

  func getShikimoriApiName() -> String {
    switch self {
    case .winter:
      "winter"
    case .spring:
      "spring"
    case .summer:
      "summer"
    case .autumn:
      "fall"
    }
  }
}

struct AiringSeason: Comparable, Equatable {
  let calendarSeason: CalendarSeason
  let year: Int

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

  init(fromJikanSeason: JikanApiClient.Season, year: Int) {
    self.calendarSeason =
      switch fromJikanSeason {
      case .fall:
        .autumn
      case .spring:
        .spring
      case .summer:
        .summer
      case .winter:
        .winter
      }

    self.year = year
  }

  init?(fromShikimoriSeasonString: String) {
    if fromShikimoriSeasonString.isEmpty {
      return nil
    }

    let stringParts = fromShikimoriSeasonString.split(separator: "_", maxSplits: 2)

    if stringParts.count != 2 {
      return nil
    }

    let calendarSeasonString = stringParts[0]
    let yearString = stringParts[1]

    let calendarSeason: CalendarSeason? =
      switch calendarSeasonString {
      case "winter":
        .winter
      case "spring":
        .spring
      case "summer":
        .summer
      case "autumn":
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

  init(fromDate: Date) {
    let year = Calendar.current.component(.year, from: fromDate)
    let monthNumber = Calendar.current.component(.month, from: fromDate)

    switch monthNumber {
    case 1, 2, 3:  // January, February, March
      self.calendarSeason = .winter
    case 4, 5, 6:  // April, May, June
      self.calendarSeason = .spring
    case 7, 8, 9:  // July, August, September
      self.calendarSeason = .summer
    default:  // October, November, December
      self.calendarSeason = .autumn
    }

    self.year = year
  }

  static func < (lhs: Self, rhs: Self) -> Bool {
    if lhs.year < rhs.year {
      return true
    }

    return lhs.calendarSeason < rhs.calendarSeason
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.year == rhs.year && lhs.calendarSeason == rhs.calendarSeason
  }

  func getLocalizedTranslation() -> String {
    "\(self.calendarSeason.getLocalizedTranslation()) \(self.year)"
  }
}

struct ShowSeasonService {
  static let CURRENT_SEASON = 0
  static let NEXT_SEASON = 1

  private let currentDate: Date

  init() {
    self.currentDate = Date()
  }

  /// 1 = next season
  /// 0 = current season
  /// -1 = previous season
  func getRelativeSeason(shift: Int) -> AiringSeason {
    let shiftedDate = Calendar.current.date(byAdding: .month, value: shift * 3, to: self.currentDate)!
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
