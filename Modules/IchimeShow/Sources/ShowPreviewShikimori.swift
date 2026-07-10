import Foundation
import ShikimoriApiClient

public struct ShowPreviewShikimori: Hashable, Identifiable {
  public let id: Int
  public let title: ShowName
  public let posterURL: URL?
  public let score: Float?
  public let airingSeason: AiringSeason?
  public let kind: ShowKind?
  public let year: Int?

  public init?(
    graphqlAnimePreview: ShikimoriApiClient.AnimeFieldsForPreview
  ) {
    guard let malIDString = graphqlAnimePreview.malId else {
      return nil
    }

    if let malID = Int(malIDString) {
      self.id = malID
    }
    else {
      return nil
    }

    self.title = .parsed(graphqlAnimePreview.name, graphqlAnimePreview.russian)

    if let score = graphqlAnimePreview.score, score > 0 {
      self.score = score
    }
    else {
      self.score = nil
    }

    if let season = graphqlAnimePreview.season {
      self.airingSeason = .init(fromShikimoriSeasonString: season)
    }
    else if let month = graphqlAnimePreview.airedOn.month, let year = graphqlAnimePreview.airedOn.year {
      self.airingSeason = .init(
        monthNumber: month,
        year: year,
      )
    }
    else {
      self.airingSeason = nil
    }

    if let kind = graphqlAnimePreview.kind {
      self.kind = .create(kind)
    }
    else {
      self.kind = nil
    }

    if let poster = graphqlAnimePreview.poster {
      self.posterURL = poster.previewAlt2xUrl
    }
    else {
      self.posterURL = nil
    }

    if let airedOnYear = graphqlAnimePreview.airedOn.year {
      self.year = airedOnYear
    }
    else {
      self.year = nil
    }
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
  }
}
