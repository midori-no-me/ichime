import Anime365ApiClient
import Foundation

struct Show: Hashable, Identifiable {
  struct Title {
    struct TranslatedTitles {
      let russian: String?
      let english: String?
      let japanese: String?
      let japaneseRomaji: String?
    }

    let full: String
    let translated: TranslatedTitles

    var compose: String {
      self.translated.japaneseRomaji ?? self.translated.english ?? self.translated.russian ?? self.full
    }
  }

  struct Description: Hashable {
    let text: String
    let source: String

    static func == (lhs: Description, rhs: Description) -> Bool {
      lhs.text == rhs.text
    }

    func hash(into hasher: inout Hasher) {
      hasher.combine(self.text)
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

  struct Genre: Identifiable {
    let id: Int
    let title: String
  }

  let id: Int
  let title: Title
  let descriptions: [Description]
  let posterUrl: URL?
  let websiteUrl: URL
  let score: Float?
  let airingSeason: AiringSeason?
  let numberOfEpisodes: Int?
  let typeTitle: String
  let broadcastType: BroadcastType
  let genres: [Genre]
  let isOngoing: Bool
  let episodePreviews: [EpisodePreview]

  static func createFromApiSeries(
    series: Anime365ApiSeries
  ) -> Show {
    let score = Float(series.myAnimeListScore) ?? 0

    return Show(
      id: series.id,
      title: Show.Title(
        full: series.title,
        translated: Show.Title.TranslatedTitles(
          russian: series.titles.ru,
          english: series.titles.en,
          japanese: series.titles.ja,
          japaneseRomaji: series.titles.romaji
        )
      ),
      descriptions: (series.descriptions ?? []).map { description in
        Show.Description(
          text: description.value,
          source: description.source
        )
      },
      posterUrl: URL(string: series.posterUrl),
      websiteUrl: URL(string: series.url)!,
      score: score <= 0 ? nil : Float(series.myAnimeListScore),
      airingSeason: AiringSeason(fromTranslatedString: series.season),
      numberOfEpisodes: series.numberOfEpisodes <= 0 ? nil : series.numberOfEpisodes,
      typeTitle: series.typeTitle,
      broadcastType: .createFromApiType(apiType: series.type),
      genres: (series.genres ?? []).map { genre in
        Show.Genre(
          id: genre.id,
          title: genre.title
        )
      },
      isOngoing: series.isAiring == 1,
      episodePreviews: (series.episodes ?? []).map { episode in
        EpisodePreview(
          id: episode.id,
          title: episode.episodeTitle.isEmpty ? nil : episode.episodeTitle,
          typeAndNumber: episode.episodeFull,
          uploadDate: episode
            .firstUploadedDateTime == "2000-01-01 00:00:00"
            ? nil : convertApiDateStringToDate(string: episode.firstUploadedDateTime)!,
          type: EpisodeType.createFromApiType(apiType: episode.episodeType),
          episodeNumber: Float(episode.episodeInt),
          isUnderProcessing: episode.isFirstUploaded == 0
        )
      }
    )
  }

  static func == (lhs: Show, rhs: Show) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(self.id)
  }
}

func getWebsiteUrlByShowId(showId: Int) -> URL {
  let urlString = String(format: "https://anime365.ru/catalog/%d", showId)

  return URL(string: urlString)!
}
