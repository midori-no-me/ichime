import Foundation

enum EpisodeType {
  case trailer
  case tv
  case other

  static func createFromApiType(apiType: String) -> Self {
    switch apiType {
    case "tv":
      return .tv
    case "preview":
      return .trailer
    default:
      return .other
    }
  }
}
