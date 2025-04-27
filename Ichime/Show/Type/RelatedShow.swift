import Foundation
import ShikimoriApiClient

struct RelatedShow: Identifiable, Hashable {
  struct TranslatedTitles {
    let russian: String?
    let japaneseRomaji: String
  }

  let myAnimeListId: Int
  let title: TranslatedTitles
  let posterUrl: URL?
  let score: Float?
  let airingSeason: AiringSeason?
  let relationKind: ShowRelationKind
  let kind: ShowKind?

  var id: Int {
    self.myAnimeListId
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  static func createValid(
    shikimoriRelation: ShikimoriApiClient.Relation,
    shikimoriBaseUrl: URL
  ) -> Self? {
    guard let anime = shikimoriRelation.anime else {
      return nil
    }

    let dateWithoutTimeFormatter = ShikimoriApiClient.ApiDateDecoder.getDateWithoutTimeFormatter()

    var airingSeason: AiringSeason? = nil

    if let airedOnString = anime.aired_on, let airedAt = dateWithoutTimeFormatter.date(from: airedOnString) {
      airingSeason = .init(fromDate: airedAt)
    }

    var posterUrl: URL? = nil

    if let image = anime.image {
      posterUrl = URL(string: shikimoriBaseUrl.absoluteString + image.original)
    }

    var score: Float? = nil

    if let scoreString = anime.score {
      if let parsedScore = Float(scoreString), parsedScore > 0 {
        score = parsedScore
      }
    }

    var kind: ShowKind? = nil

    if let shikimoriAnimeKind = anime.kind {
      kind = .create(shikimoriAnimeKind)
    }

    return Self(
      myAnimeListId: anime.id,
      title: .init(
        russian: anime.russian,
        japaneseRomaji: anime.name
      ),
      posterUrl: posterUrl,
      score: score,
      airingSeason: airingSeason,
      relationKind: .create(shikimoriRelation.relation_russian),
      kind: kind
    )
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
  }
}
