import Foundation

func formatRelativeDate(_ releaseDate: Date?) -> String {
  guard let releaseDate = releaseDate else {
    return "???"
  }

  let now = Date()
  let calendar = Calendar.current

  if calendar.isDateInToday(releaseDate) || calendar.isDateInYesterday(releaseDate) {
    let formatStyle = Date.RelativeFormatStyle(presentation: .named)

    return releaseDate.formatted(formatStyle)
  }
  else {
    let formatter = DateFormatter()

    formatter.setLocalizedDateFormatFromTemplate("d MMMM")

    if !calendar.isDate(releaseDate, equalTo: now, toGranularity: .year) {
      formatter.setLocalizedDateFormatFromTemplate("d MMMM yyyy")
    }

    return formatter.string(from: releaseDate)
  }
}

func formatTime(_ releaseDate: Date) -> String {
  let relativeDateFormatter = DateFormatter()
  relativeDateFormatter.timeStyle = .short
  relativeDateFormatter.dateStyle = .none

  return relativeDateFormatter.string(from: releaseDate)
}

/// Примеры:
///
/// Соседние с текущим дни:
///
/// - Вчера в 17:00
/// - Сегодня в 17:00
/// - Завтра в 17:00
///
/// Дата в этом году:
///
/// - четверг, 18 января в 17:00
///
/// Дата в году, номер которого отличается от текущего:
///
/// - четверг, 18 января 2024 г. в 17:00
func formatRelativeDateWithWeekdayNameAndDateAndTime(_ date: Date) -> String {
  let calendar = Calendar.current
  let now = Date.now
  let formatter = DateFormatter()

  if calendar.isDateInYesterday(date) || calendar.isDateInToday(date) || calendar.isDateInTomorrow(date) {
    // Пример: Завтра в 17:00
    formatter.dateStyle = .full
    formatter.timeStyle = .short
    formatter.doesRelativeDateFormatting = true
  }
  else if calendar.isDate(date, equalTo: now, toGranularity: .year) {
    // Пример: четверг, 18 января в 17:00
    formatter.setLocalizedDateFormatFromTemplate("EEEE d MMMM HH mm")
  }
  else {
    // Пример: четверг, 18 января 2024 г. в 17:00
    formatter.setLocalizedDateFormatFromTemplate("EEEE d MMMM yyyy HH mm")
  }
  return formatter.string(from: date)
}

/// Примеры:
///
/// Соседние с текущим дни:
///
/// - Вчера
/// - Сегодня
/// - Завтра
///
/// Дата в этом году:
///
/// - четверг, 18 января
///
/// Дата в году, номер которого отличается от текущего:
///
/// - четверг, 18 января 2024 г.
func formatRelativeDateWithWeekdayNameAndDate(_ date: Date) -> String {
  let calendar = Calendar.current
  let now = Date.now
  let formatter = DateFormatter()

  if calendar.isDateInYesterday(date) || calendar.isDateInToday(date) || calendar.isDateInTomorrow(date) {
    // Пример: Завтра
    formatter.dateStyle = .full
    formatter.timeStyle = .none
    formatter.doesRelativeDateFormatting = true
  }
  else if calendar.isDate(date, equalTo: now, toGranularity: .year) {
    // Пример: четверг, 18 января
    formatter.setLocalizedDateFormatFromTemplate("EEEE d MMMM")
  }
  else {
    // Пример: четверг, 18 января 2024 г.
    formatter.setLocalizedDateFormatFromTemplate("EEEE d MMMM yyyy")
  }
  return formatter.string(from: date)
}

enum Weekday {
  case monday
  case tuesday
  case wednesday
  case thursday
  case friday
  case saturday
  case sunday

  func calendarIndex() -> Int {
    switch self {
    case .monday: return 2
    case .tuesday: return 3
    case .wednesday: return 4
    case .thursday: return 5
    case .friday: return 6
    case .saturday: return 7
    case .sunday: return 1
    }
  }
}

/// Возвращает ближайшую дату из будущего
func getNextClosestDate(
  weekday: Weekday,
  time: (hour: Int, minute: Int),
  timezone: TimeZone
) -> Date? {
  let now = Date()

  var components = DateComponents()
  components.hour = time.hour
  components.minute = time.minute
  components.weekday = weekday.calendarIndex()

  var calendar = Calendar.current
  calendar.timeZone = timezone

  guard
    let nextClosestDate = calendar.nextDate(
      after: now,
      matching: components,
      matchingPolicy: .nextTime
    )
  else {
    return nil
  }

  return nextClosestDate
}
