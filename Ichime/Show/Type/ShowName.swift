enum ShowName {
  case parsed(String, String?)
  case unparsed(String)

  static func fromFullName(_ fullName: String) -> Self {
    let components = fullName.components(separatedBy: " / ")

    if components.count != 2 {
      return .unparsed(fullName)
    }

    return .parsed(components[1].trim(), components[0].trim())
  }

  func getFullName() -> String {
    switch self {
    case let .unparsed(fullName):
      return fullName

    case let .parsed(romaji, russian):
      var components: [String] = []

      if let russian = russian {
        components.append(russian)
      }

      components.append(romaji)

      return components.joined(separator: " / ")
    }
  }

  func getRomajiOrFullName() -> String {
    switch self {
    case let .unparsed(fullName):
      return fullName

    case let .parsed(romaji, _):
      return romaji
    }
  }

  func getRussian() -> String? {
    switch self {
    case .unparsed:
      return nil

    case let .parsed(_, russian):
      return russian
    }
  }
}
