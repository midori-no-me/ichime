import Anime365Kit

public enum MomentSorting: Sendable {
  case newest
  case popular

  public var anime365: Anime365Kit.MomentSorting {
    switch self {
    case .newest:
      return .new
    case .popular:
      return .popular
    }
  }
}
