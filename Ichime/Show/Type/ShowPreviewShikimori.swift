import Foundation
import ShikimoriApiClient

struct ShowPreviewShikimori: Hashable, Identifiable {
  let id: Int
  let title: ShowName
  let posterUrl: URL?
  let score: Float?
  let airingSeason: AiringSeason?
  let kind: ShowKind?

  init(
    anime: ShikimoriApiClient.AnimePreview,
    shikimoriBaseUrl: URL
  ) {
    self.id = anime.id
    self.title = .parsed(anime.name, anime.russian != "" ? anime.russian : nil)

    if let image = anime.image {
      self.posterUrl = URL(string: shikimoriBaseUrl.absoluteString + image.original)
    }
    else {
      self.posterUrl = nil
    }

    if let scoreString = anime.score, let score = Float(scoreString), score > 0 {
      self.score = score
    }
    else {
      self.score = nil
    }

    let dateWithoutTimeFormatter = ShikimoriApiClient.ApiDateDecoder.getDateWithoutTimeFormatter()

    if let airedOnString = anime.aired_on, let airedAt = dateWithoutTimeFormatter.date(from: airedOnString) {
      self.airingSeason = .init(fromDate: airedAt)
    }
    else {
      self.airingSeason = nil
    }

    if let kind = anime.kind {
      self.kind = .create(kind)
    }
    else {
      self.kind = nil
    }
  }

  init?(
    graphqlAnimePreview: ShikimoriApiClient.GraphQLAnimePreview
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
