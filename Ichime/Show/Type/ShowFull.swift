import Anime365ApiClient
import Foundation
import JikanApiClient
import ShikimoriApiClient

struct ShowFull {
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

  let id: Int
  let myAnimeListId: Int
  let title: ShowName
  let descriptions: [Description]
  let posterUrl: URL?
  let score: Float?
  let airingSeason: AiringSeason?
  let numberOfEpisodes: Int?
  let latestAiredEpisodeNumber: Int?
  let hasEpisodes: Bool
  let kind: ShowKind?
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
    shikimoriAnime: ShikimoriApiClient.Anime?,
    shikimoriScreenshots: [ShikimoriApiClient.ImageVariants],
    shikimoriBaseUrl: URL,
    jikanCharacterRoles: [JikanApiClient.CharacterRole],
    jikanStaffMembers: [JikanApiClient.StaffMember],
    moments: [Moment],
    relatedShows: [GroupedRelatedShows]
  ) -> Self {
    let score = Float(anime365Series.myAnimeListScore) ?? 0
    let totalEpisodes = anime365Series.numberOfEpisodes <= 0 ? nil : anime365Series.numberOfEpisodes
    var kind: ShowKind? = nil

    if let seriesType = anime365Series.type {
      kind = .create(seriesType)
    }

    var title = ShowName.unparsed(anime365Series.title)

    if let romajiTitle = anime365Series.titles.romaji {
      title = .parsed(romajiTitle, anime365Series.titles.ru)
    }

    return Self(
      id: anime365Series.id,
      myAnimeListId: anime365Series.myAnimeListId,
      title: title,
      descriptions: (anime365Series.descriptions ?? []).map { description in
        Self.Description.createFiltered(
          text: description.value,
          source: description.source
        )
      },
      posterUrl: anime365Series.posterUrl,
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
      kind: kind,
      genres: (anime365Series.genres ?? []).map { .init(fromAnime365Genre: $0) },
      isOngoing: anime365Series.isAiring == 1,
      studios: (shikimoriAnime?.studios ?? []).map {
        .init(fromShikimoriStudio: $0, shikimoriBaseUrl: shikimoriBaseUrl)
      },
      screenshots: shikimoriScreenshots.map { screenshot in
        URL(string: shikimoriBaseUrl.absoluteString + screenshot.original)!
      },
      nextEpisodeReleasesAt: shikimoriAnime?.next_episode_at,
      characters: jikanCharacterRoles.map { .create(jikanCharacterRole: $0) },
      staffMembers: jikanStaffMembers.map { .create(jikanStaffMember: $0) },
      moments: moments,
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
        jikanEpisode: nil,
        totalEpisodes: totalEpisodes
      )

      guard let episodeInfo else {
        continue
      }

      guard let episodeNumber = episodeInfo.episodeNumber else {
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
        jikanEpisode: nil,
        totalEpisodes: totalEpisodes
      )

      if episodeInfo != nil {
        return true
      }
    }

    return false
  }
}
