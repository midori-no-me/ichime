import Foundation

public struct Translation: Sendable, Decodable {
  public let id: Int
  public let activeDateTime: Date
  public let addedDateTime: Date
  public let isActive: Int
  public let qualityType: String
  public let typeKind: String
  public let typeLang: String
  public let authorsSummary: String
  public let height: Int
}

public struct TranslationFull: Sendable, Decodable {
  public let episode: Episode
  public let series: Series
}
