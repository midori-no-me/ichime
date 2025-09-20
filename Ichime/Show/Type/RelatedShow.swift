import Foundation
import ShikimoriApiClient

struct RelatedShow: Identifiable, Hashable {
  let myAnimeListId: Int
  let title: ShowName
  let posterUrl: URL?
  let score: Float?
  let airingSeason: AiringSeason?
  let relationKind: ShowRelationKind
  let kind: ShowKind?

  var id: Int {
    self.myAnimeListId
  }

  init?(
    fromShikimoriRelation: ShikimoriApiClient.Relation,
    shikimoriBaseUrl: URL
  ) {
    guard let anime = fromShikimoriRelation.anime else {
      return nil
    }

    let dateWithoutTimeFormatter = ShikimoriApiClient.ApiDateDecoder.getDateWithoutTimeFormatter()

    if let airedOnString = anime.aired_on, let airedAt = dateWithoutTimeFormatter.date(from: airedOnString) {
      self.airingSeason = .init(fromDate: airedAt)
    }
    else {
      self.airingSeason = nil
    }

    if let image = anime.image {
      self.posterUrl = URL(string: shikimoriBaseUrl.absoluteString + image.original)
    }
    else {
      self.posterUrl = nil
    }

    if let scoreString = anime.score, let parsedScore = Float(scoreString), parsedScore > 0 {
      self.score = parsedScore
    }
    else {
      self.score = nil
    }

    if let shikimoriAnimeKind = anime.kind {
      self.kind = .create(shikimoriAnimeKind)
    }
    else {
      self.kind = nil
    }

    self.myAnimeListId = anime.id

    self.title = .parsed(anime.name, anime.russian)

    self.relationKind = .create(fromShikimoriRelation.relation_russian)
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
  }
}
