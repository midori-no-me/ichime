enum EpisodeTranslationGroupType {
  case russianSubtitles
  case russianVoiceOver
  case englishSubtitles
  case englishVoiceOver
  case japanese
  case other

  var priority: Int {
    switch self {
    case .russianSubtitles:
      100
    case .russianVoiceOver:
      80
    case .englishSubtitles:
      60
    case .englishVoiceOver:
      40
    case .japanese:
      20
    case .other:
      0
    }
  }

  var title: String {
    switch self {
    case .russianSubtitles:
      "Русские субтитры"
    case .russianVoiceOver:
      "Русская озвучка"
    case .englishSubtitles:
      "Английские субтитры"
    case .englishVoiceOver:
      "Английская озвучка"
    case .japanese:
      "Японский"
    case .other:
      "Прочее"
    }
  }
}
