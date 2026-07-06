enum AnimeListScore: Int, CaseIterable {
  case none = 0
  case ten = 10
  case nine = 9
  case eight = 8
  case seven = 7
  case six = 6
  case five = 5
  case four = 4
  case three = 3
  case two = 2
  case one = 1

  var label: String {
    switch self {
    case .none:
      return "—"
    case .ten:
      return String(localized: "10 — Шедевр")
    case .nine:
      return String(localized: "9 — Великолепно")
    case .eight:
      return String(localized: "8 — Очень хорошо")
    case .seven:
      return String(localized: "7 — Хорошо")
    case .six:
      return String(localized: "6 — Неплохо")
    case .five:
      return String(localized: "5 — Средне")
    case .four:
      return String(localized: "4 — Плохо")
    case .three:
      return String(localized: "3 — Очень плохо")
    case .two:
      return String(localized: "2 — Ужасно")
    case .one:
      return String(localized: "1 — Отвратительно")
    }
  }
}
