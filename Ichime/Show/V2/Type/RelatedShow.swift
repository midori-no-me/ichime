import Foundation
import ShikimoriApiClient

struct RelatedShow {
  struct TranslatedTitles {
    let russian: String?
    let japaneseRomaji: String
  }

  let myAnimeListId: Int
  let title: TranslatedTitles
  let posterUrl: URL?
  let score: Float?
  let airingSeason: AiringSeason?
  let relationTitle: String

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

    return Self(
      myAnimeListId: anime.id,
      title: .init(
        russian: anime.russian,
        japaneseRomaji: anime.name
      ),
      posterUrl: posterUrl,
      score: score,
      airingSeason: airingSeason,
      relationTitle: shikimoriRelation.relation_russian
    )
  }
}
