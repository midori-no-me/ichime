protocol ShowName {
  func getFullName() -> String
}

struct UnparsedShowName: ShowName {
  let fullName: String

  func getFullName() -> String {
    self.fullName
  }
}

struct ParsedShowName: ShowName {
  let russian: String?
  let romaji: String

  func getFullName() -> String {
    var components: [String] = []

    if let russian = russian {
      components.append(russian)
    }

    components.append(self.romaji)

    return components.joined(separator: " / ")
  }
}
