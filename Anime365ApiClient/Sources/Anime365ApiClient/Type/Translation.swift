import Foundation

public struct Translation: Decodable {
  public let id: Int
  public let activeDateTime: Date
  public let addedDateTime: Date
  public let authorsList: [String]
  public let isActive: Int
  public let priority: Int
  public let qualityType: String
  public let typeKind: String
  public let typeLang: String
  public let updatedDateTime: Date
  public let title: String
  public let url: String
  public let authorsSummary: String
  public let duration: String
  public let width: Int
  public let height: Int
  public let seriesId: Int
  public let episodeId: Int
}
