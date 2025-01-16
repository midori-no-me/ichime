import Anime365ApiClient
import Foundation
import ShikimoriApiClient

struct ShowFull {
  static func create(
    anime365Series: Anime365ApiSeries,
    shikimoriAnime: AnimeV1,
    shikimoriBaseUrl: URL
  ) -> ShowFull {
    let score = Float(anime365Series.myAnimeListScore) ?? 0

    return ShowFull(
      id: anime365Series.id,
      title: ShowFull.Title(
        full: anime365Series.title,
        translated: ShowFull.Title.TranslatedTitles(
          russian: anime365Series.titles.ru,
          english: anime365Series.titles.en,
          japanese: anime365Series.titles.ja,
          japaneseRomaji: anime365Series.titles.romaji
        )
      ),
      descriptions: (anime365Series.descriptions ?? []).map { description in
        ShowFull.Description(
          text: description.value,
          source: description.source
        )
      },
      posterUrl: URL(string: anime365Series.posterUrl),
      score: score <= 0 ? nil : Float(anime365Series.myAnimeListScore),
      airingSeason: AiringSeason(fromTranslatedString: anime365Series.season),
      numberOfEpisodes: anime365Series.numberOfEpisodes <= 0 ? nil : anime365Series.numberOfEpisodes,
      typeTitle: anime365Series.typeTitle,
      broadcastType: .createFromApiType(apiType: anime365Series.type),
      genres: (anime365Series.genres ?? []).map { genre in
        ShowFull.Genre(
          id: genre.id,
          title: genre.title
        )
      },
      isOngoing: anime365Series.isAiring == 1,
      episodePreviews: (anime365Series.episodes ?? []).map { episode in
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
      },
      myAnimeListId: anime365Series.myAnimeListId,
      studios: shikimoriAnime.studios.map { studio in
        var imageUrl: URL? = nil

        if let imagePath = studio.image {
          imageUrl = URL(string: shikimoriBaseUrl.absoluteString + imagePath)
        }

        return ShowFull.Studio(
          id: studio.id,
          name: studio.name,
          image: imageUrl
        )
      },
      screenshots: shikimoriAnime.screenshots.map { screenshot in
        URL(string: shikimoriBaseUrl.absoluteString + screenshot.original)!
      }
    )
  }

  let id: Int
  let title: Title
  let descriptions: [Description]
  let posterUrl: URL?
  let score: Float?
  let airingSeason: AiringSeason?
  let numberOfEpisodes: Int?
  let typeTitle: String
  let broadcastType: BroadcastType
  let genres: [Genre]
  let isOngoing: Bool
  let episodePreviews: [EpisodePreview]
  let myAnimeListId: Int
  let studios: [Studio]
  let screenshots: [URL]

  struct Title {
    let full: String
    let translated: TranslatedTitles

    struct TranslatedTitles {
      let russian: String?
      let english: String?
      let japanese: String?
      let japaneseRomaji: String?
    }

    var compose: String {
      self.translated.japaneseRomaji ?? self.translated.english ?? self.translated.russian ?? self.full
    }
  }

  struct Description: Hashable {
    static func == (lhs: Description, rhs: Description) -> Bool {
      lhs.text == rhs.text
    }

    func hash(into hasher: inout Hasher) {
      hasher.combine(self.text)
    }

    let text: String
    let source: String
  }

  enum BroadcastType {
    static func createFromApiType(apiType: String) -> Self {
      switch apiType {
      case "tv":
        return .tv
      default:
        return .other
      }
    }

    case tv
    case other
  }

  struct Genre: Identifiable {
    let id: Int
    let title: String
  }

  struct Studio: Identifiable {
    let id: Int
    let name: String
    let image: URL?
  }
}
