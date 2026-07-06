import Anime365Kit

enum MomentSorting {
  case newest
  case popular

  var anime365: Anime365Kit.MomentSorting {
    switch self {
    case .newest:
      return .new
    case .popular:
      return .popular
    }
  }
}
