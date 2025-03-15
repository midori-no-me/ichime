enum ShowRelationKind {
  case adaptation
  case alternativeSetting
  case alternativeVersion
  case sharedCharacters
  case fullStory
  case other
  case parentStory
  case prequel
  case sequel
  case sideStory
  case spinOff
  case summary

  var title: String {
    switch self {
    case .adaptation:
      "Адаптация"
    case .alternativeSetting:
      "Альтернативная вселенная"
    case .alternativeVersion:
      "Альтернативная история"
    case .sharedCharacters:
      "Общие персонажи"
    case .fullStory:
      "Развёрнутая история"
    case .other:
      "Прочее"
    case .parentStory:
      "Изначальная история"
    case .prequel:
      "Предыстория"
    case .sequel:
      "Продолжение"
    case .sideStory:
      "Другая история"
    case .spinOff:
      "Ответвление от оригинала"
    case .summary:
      "Обобщение"
    }
  }

  var priority: Int {
    switch self {
    case .sequel:
      100
    case .prequel:
      90
    case .summary:
      80
    case .sideStory:
      70
    case .spinOff:
      60
    case .fullStory:
      50
    case .parentStory:
      40
    case .alternativeVersion:
      30
    case .alternativeSetting:
      20
    case .sharedCharacters:
      10
    case .other:
      5
    case .adaptation:
      0
    }
  }

  static func create(_ fromShikimoriApiString: String) -> Self {
    switch fromShikimoriApiString {
    case "Адаптация":
      .adaptation
    case "Альтернативная вселенная":
      .alternativeSetting
    case "Альтернативная история":
      .alternativeVersion
    case "Общий персонаж":
      .sharedCharacters
    case "Развёрнутая история":
      .fullStory
    case "Прочее":
      .other
    case "Изначальная история":
      .parentStory
    case "Предыстория":
      .prequel
    case "Продолжение":
      .sequel
    case "Другая история":
      .sideStory
    case "Ответвление от оригинала":
      .spinOff
    case "Обобщение":
      .summary
    default:
      .other
    }
  }
}
