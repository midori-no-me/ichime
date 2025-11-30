import Foundation
import ShikimoriApiClient

struct ShowPreviewShikimori: Hashable, Identifiable {
  let id: Int
  let title: ShowName
  let posterUrl: URL?
  let score: Float?
  let airingSeason: AiringSeason?
  let kind: ShowKind?

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
    else if graphqlAnimePreview.airedOn.month > 0 && graphqlAnimePreview.airedOn.year > 1900 {
      self.airingSeason = .init(
        monthNumber: graphqlAnimePreview.airedOn.month,
        year: graphqlAnimePreview.airedOn.year,
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
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
  }
}
