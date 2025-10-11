enum AgeRating {
  case g
  case pg
  case pg_13
  case r
  case r_plus
  case rx

  var shortLabel: String {
    switch self {
    case .g:
      "G"
    case .pg:
      "PG"
    case .pg_13:
      "PG-13"
    case .r:
      "R"
    case .r_plus:
      "R+"
    case .rx:
      "Rx"
    }
  }

  static func create(fromShikimoriString shikimoriString: String) -> Self? {
    switch shikimoriString {
    case "g":
      .g
    case "pg":
      .pg
    case "pg_13":
      .pg_13
    case "r":
      .r
    case "r_plus":
      .r_plus
    case "rx":
      .rx
    default:
      nil
    }
  }
}
