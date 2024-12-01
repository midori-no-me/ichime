import Foundation

enum EpisodeType {
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

  case trailer
  case tv
  case other
}
