import Foundation
import ShikimoriApiClient

struct ShowPreviewShikimori: Hashable, Identifiable {
  let id: Int
  let title: ShowName
  let posterUrl: URL?
  let score: Float?
  let airingSeason: AiringSeason?
  let kind: ShowKind?
  let year: Int?

  init?(
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
      self.posterUrl = poster.previewAlt2xUrl
    }
    else {
      self.posterUrl = nil
    }

    if let airedOnYear = graphqlAnimePreview.airedOn.year {
      self.year = airedOnYear
    }
    else {
      self.year = nil
    }
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
  }
}
