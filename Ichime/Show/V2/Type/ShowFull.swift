import Anime365ApiClient
import Foundation
import JikanApiClient
import ScraperAPI
import ShikimoriApiClient

struct ShowFull {
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

  struct Description: Hashable {
    let text: String
    let source: String

    static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.text == rhs.text
    }

    static func createFiltered(
      text: String,
      source: String
    ) -> Self {
      let filteredText = text.replacing(
        try! Regex(#"\n+"#),
        with: "\n\n"
      )

      return Self(
        text: filteredText,
        source: source
      )
    }

    func hash(into hasher: inout Hasher) {
      hasher.combine(self.text)
    }
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

  let id: Int
  let title: Title
  let descriptions: [Description]
  let posterUrl: URL?
  let score: Float?
  let airingSeason: AiringSeason?
  let numberOfEpisodes: Int?
  let latestAiredEpisodeNumber: Int?
  let hasEpisodes: Bool
  let typeTitle: String  // TODO: Поменять на ShowKind
  let genres: [Genre]
  let isOngoing: Bool
  let studios: [Studio]
  let screenshots: [URL]
  let nextEpisodeReleasesAt: Date?
  let characters: [Character]
  let staffMembers: [StaffMember]
  let moments: [Moment]
  let relatedShows: [GroupedRelatedShows]

  static func create(
    anime365Series: Anime365ApiClient.SeriesFull,
    shikimoriAnime: ShikimoriApiClient.AnimeV1,
    shikimoriScreenshots: [ShikimoriApiClient.AnimeV1.Screenshot],
    shikimoriBaseUrl: URL,
    jikanCharacterRoles: [JikanApiClient.CharacterRole],
    jikanStaffMembers: [JikanApiClient.StaffMember],
    anime365Moments: [ScraperAPI.Types.Moment],
    relatedShows: [GroupedRelatedShows]
  ) -> Self {
    let score = Float(anime365Series.myAnimeListScore) ?? 0
    let totalEpisodes = anime365Series.numberOfEpisodes <= 0 ? nil : anime365Series.numberOfEpisodes

    return Self(
      id: anime365Series.id,
      title: Self.Title(
        full: anime365Series.title,
        translated: Self.Title.TranslatedTitles(
          russian: anime365Series.titles.ru,
          english: anime365Series.titles.en,
          japaneseRomaji: anime365Series.titles.romaji
        )
      ),
      descriptions: (anime365Series.descriptions ?? []).map { description in
        Self.Description.createFiltered(
          text: description.value,
          source: description.source
        )
      },
      posterUrl: URL(string: anime365Series.posterUrl),
      score: score <= 0 ? nil : Float(anime365Series.myAnimeListScore),
      airingSeason: AiringSeason(fromTranslatedString: anime365Series.season),
      numberOfEpisodes: anime365Series.numberOfEpisodes <= 0 ? nil : anime365Series.numberOfEpisodes,
      latestAiredEpisodeNumber: Self.getLatestAiredEpisodeNumber(
        anime365Episodes: anime365Series.episodes ?? [],
        totalEpisodes: totalEpisodes
      ),
      hasEpisodes: Self.calculateShowHasUploadedEpisodesToWatch(
        anime365Episodes: anime365Series.episodes ?? [],
        totalEpisodes: totalEpisodes
      ),
      typeTitle: anime365Series.typeTitle,
      genres: (anime365Series.genres ?? []).map { genre in
        Self.Genre(
          id: genre.id,
          title: genre.title
        )
      },
      isOngoing: anime365Series.isAiring == 1,
      studios: shikimoriAnime.studios.map { studio in
        var imageUrl: URL? = nil

        if let imagePath = studio.image {
          imageUrl = URL(string: shikimoriBaseUrl.absoluteString + imagePath)
        }

        return Self.Studio(
          id: studio.id,
          name: studio.name,
          image: imageUrl
        )
      },
      screenshots: shikimoriScreenshots.map { screenshot in
        URL(string: shikimoriBaseUrl.absoluteString + screenshot.original)!
      },
      nextEpisodeReleasesAt: shikimoriAnime.next_episode_at,
      characters: jikanCharacterRoles.map { .create(jikanCharacterRole: $0) },
      staffMembers: jikanStaffMembers.map { .create(jikanStaffMember: $0) },
      moments: anime365Moments.map { .create(anime365Moment: $0) },
      relatedShows: relatedShows
    )
  }

  private static func getLatestAiredEpisodeNumber(
    anime365Episodes: [Anime365ApiClient.Episode],
    totalEpisodes: Int?
  ) -> Int? {
    var largestEpisodeNumber: Int? = nil

    for anime365Episode in anime365Episodes {
      let episodeInfo = EpisodeInfo.createValid(
        anime365EpisodePreview: anime365Episode,
        jikanEpisode: nil
      )

      guard let episodeInfo else {
        continue
      }

      guard let episodeNumber = episodeInfo.episodeNumber else {
        continue
      }

      if let totalEpisodes, episodeNumber > totalEpisodes {
        continue
      }

      if largestEpisodeNumber == nil {
        largestEpisodeNumber = episodeNumber

        continue
      }

      if episodeNumber > largestEpisodeNumber! {
        largestEpisodeNumber = episodeNumber
      }
    }

    return largestEpisodeNumber
  }

  private static func calculateShowHasUploadedEpisodesToWatch(
    anime365Episodes: [Anime365ApiClient.Episode],
    totalEpisodes: Int?
  ) -> Bool {
    for anime365Episode in anime365Episodes {
      let episodeInfo = EpisodeInfo.createValid(
        anime365EpisodePreview: anime365Episode,
        jikanEpisode: nil
      )

      guard let episodeInfo else {
        continue
      }

      if let episodeNumber = episodeInfo.episodeNumber, let totalEpisodes {
        if episodeNumber > totalEpisodes {
          continue
        }
      }

      return true
    }

    return false
  }
}
