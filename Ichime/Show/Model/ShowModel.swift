import Anime365ApiClient
import Foundation

struct Show: Hashable, Identifiable {
  struct Title {
    struct TranslatedTitles {
      let russian: String?
      let english: String?
      let japaneseRomaji: String?
    }

    let full: String
    let translated: TranslatedTitles

    var compose: String {
      self.translated.japaneseRomaji ?? self.translated.english ?? self.translated.russian ?? self.full
    }
  }

  enum BroadcastType {
    case tv
    case other

    static func createFromApiType(apiType: String) -> Self {
      switch apiType {
      case "tv":
        return .tv
      default:
        return .other
      }
    }
  }

  let id: Int
  let title: Title
  let posterUrl: URL?
  let score: Float?
  let airingSeason: AiringSeason?
  let typeTitle: String
  let broadcastType: BroadcastType

  static func createFromApiSeries(
    series: Anime365ApiClient.SeriesFull
  ) -> Self {
    let score = Float(series.myAnimeListScore) ?? 0

    return Self(
      id: series.id,
      title: Self.Title(
        full: series.title,
        translated: Self.Title.TranslatedTitles(
          russian: series.titles.ru,
          english: series.titles.en,
          japaneseRomaji: series.titles.romaji
        )
      ),
      posterUrl: URL(string: series.posterUrl),
      score: score <= 0 ? nil : Float(series.myAnimeListScore),
      airingSeason: AiringSeason(fromTranslatedString: series.season),
      typeTitle: series.typeTitle,
      broadcastType: .createFromApiType(apiType: series.type)
    )
  }

  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
  }
}
