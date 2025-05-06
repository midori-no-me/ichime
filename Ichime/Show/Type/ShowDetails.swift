import Anime365ApiClient
import Foundation
import JikanApiClient
import OrderedCollections
import ShikimoriApiClient

struct ShowDetails {
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
  let scoredBy: Int?
  let rank: Int?
  let popularity: Int?
  let members: Int?
  let favorites: Int?
  let airingSeason: AiringSeason?
  let numberOfEpisodes: Int?
  let latestAiredEpisodeNumber: Int?
  let hasEpisodes: Bool
  let kind: ShowKind?
  let genres: OrderedSet<Genre>
  let isOngoing: Bool
  let studios: OrderedSet<Studio>
  let nextEpisodeReleasesAt: Date?
  let source: String?

  init(
    anime365Series: Anime365ApiClient.SeriesFull,
    shikimoriAnime: ShikimoriApiClient.Anime?,
    shikimoriBaseUrl: URL,
    jikanAnime: JikanApiClient.Anime?
  ) {
    let totalEpisodes = anime365Series.numberOfEpisodes <= 0 ? nil : anime365Series.numberOfEpisodes

    if let seriesType = anime365Series.type {
      self.kind = .create(seriesType)
    }
    else {
      self.kind = nil
    }

    if let romajiTitle = anime365Series.titles.romaji {
      self.title = .parsed(romajiTitle, anime365Series.titles.ru)
    }
    else {
      self.title = .unparsed(anime365Series.title)
    }

    if let score = Float(anime365Series.myAnimeListScore), score > 0 {
      self.score = score
    }
    else {
      self.score = nil
    }

    if let scoredBy = jikanAnime?.scored_by, scoredBy > 0 {
      self.scoredBy = scoredBy
    }
    else {
      self.scoredBy = nil
    }

    if let rank = jikanAnime?.rank, rank > 0 {
      self.rank = rank
    }
    else {
      self.rank = nil
    }

    if let popularity = jikanAnime?.popularity, popularity > 0 {
      self.popularity = popularity
    }
    else {
      self.popularity = nil
    }

    if let members = jikanAnime?.members, members > 0 {
      self.members = members
    }
    else {
      self.members = nil
    }

    if let favorites = jikanAnime?.favorites, favorites > 0 {
      self.favorites = favorites
    }
    else {
      self.favorites = nil
    }

    self.id = anime365Series.id
    self.myAnimeListId = anime365Series.myAnimeListId
    self.descriptions = (anime365Series.descriptions ?? []).map { description in
      Self.Description.createFiltered(
        text: description.value,
        source: description.source
      )
    }
    self.posterUrl = anime365Series.posterUrl

    /// Anime 365 выдумывает сезон, если сезон не известен или известен только год, поэтому если нам пришло аниме из Jikan, то берем информацию о сезоне оттуда
    if let jikanAnime {
      if let jikanSeason = jikanAnime.season, let jikanYear = jikanAnime.year {
        self.airingSeason = .init(fromJikanSeason: jikanSeason, year: jikanYear)
      }
      else {
        self.airingSeason = nil
      }
    }
    else {
      self.airingSeason = .init(fromTranslatedString: anime365Series.season)
    }

    self.numberOfEpisodes = totalEpisodes
    self.latestAiredEpisodeNumber = Self.getLatestAiredEpisodeNumber(
      anime365Episodes: anime365Series.episodes ?? [],
      totalEpisodes: totalEpisodes
    )
    self.hasEpisodes = Self.calculateShowHasUploadedEpisodesToWatch(
      anime365Episodes: anime365Series.episodes ?? [],
      totalEpisodes: totalEpisodes
    )
    self.genres = .init((anime365Series.genres ?? []).map { .init(fromAnime365Genre: $0) })
    self.isOngoing = anime365Series.isAiring == 1
    self.studios = .init(
      (shikimoriAnime?.studios ?? []).map {
        .init(fromShikimoriStudio: $0, shikimoriBaseUrl: shikimoriBaseUrl)
      }
    )
    self.nextEpisodeReleasesAt = shikimoriAnime?.next_episode_at
    self.source = jikanAnime?.source
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
