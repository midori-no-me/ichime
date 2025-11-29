import ShikimoriApiClient

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

  static func create(_ fromShikimoriRelationKind: ShikimoriApiClient.RelationKind) -> Self {
    switch fromShikimoriRelationKind {
    case .adaptation:
      return .adaptation
    case .alternative_setting:
      return .alternativeSetting
    case .alternative_version:
      return .alternativeVersion
    case .character:
      return .sharedCharacters
    case .full_story:
      return .fullStory
    case .parent_story:
      return .parentStory
    case .prequel:
      return .prequel
    case .sequel:
      return .sequel
    case .side_story:
      return .sideStory
    case .spin_off:
      return .spinOff
    case .summary:
      return .summary
    default:
      return .other
    }
  }
}
