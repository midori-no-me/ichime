import Anime365Kit
import Foundation
import JikanApiClient
import OrderedCollections
import ShikimoriApiClient

public struct ShowDetails {
  public struct Description: Hashable {
    public let text: String
    public let source: String

    public var singleLineText: String {
      self.text.replacing("\n", with: " ").replacing(/\ +/, with: " ")
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.text == rhs.text
    }

    public static func createFiltered(
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

    public func hash(into hasher: inout Hasher) {
      hasher.combine(self.text)
    }
  }

  public let id: Int
  public let myAnimeListID: Int
  public let title: ShowName
  public let descriptions: [Description]
  public let posterURL: URL?
  public let score: Float?
  public let airingYear: Int?
  public let airingSeason: AiringSeason?
  public let numberOfEpisodes: Int?
  public let latestAiredEpisodeNumber: Int?
  public let hasEpisodes: Bool
  public let kind: ShowKind?
  public let genres: OrderedSet<Genre>
  public let studios: OrderedSet<Studio>
  public let nextEpisodeReleasesAt: Date?
  public let ageRating: AgeRating?

  public init(
    anime365Series: Anime365Kit.SeriesFull,
    shikimoriAnime: ShikimoriApiClient.Anime?,
    shikimoriBaseURL: URL,
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

    self.id = anime365Series.id
    self.myAnimeListID = anime365Series.myAnimeListId
    self.descriptions = (anime365Series.descriptions ?? []).map { description in
      Self.Description.createFiltered(
        text: description.value,
        source: description.source
      )
    }
    self.posterURL = anime365Series.posterUrl

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

    if let jikanAnime, let jikanYear = jikanAnime.aired.prop.from.year {
      self.airingYear = jikanYear
    }
    else {
      self.airingYear = nil
    }

    self.numberOfEpisodes = totalEpisodes
    self.latestAiredEpisodeNumber = (anime365Series.episodes ?? [])
      .compactMap { Int($0.episodeInt) }
      .max()
    self.hasEpisodes = Self.calculateShowHasUploadedEpisodesToWatch(
      anime365Episodes: anime365Series.episodes ?? [],
    )
    self.genres = .init((anime365Series.genres ?? []).map { .init(fromAnime365Genre: $0) })
    self.studios = .init(
      (shikimoriAnime?.studios ?? []).map {
        .init(fromShikimoriStudio: $0, shikimoriBaseURL: shikimoriBaseURL)
      }
    )
    self.nextEpisodeReleasesAt = shikimoriAnime?.next_episode_at

    if let shikimoriRating = shikimoriAnime?.rating {
      self.ageRating = .create(fromShikimoriString: shikimoriRating)
    }
    else {
      self.ageRating = nil
    }
  }

  private static func calculateShowHasUploadedEpisodesToWatch(
    anime365Episodes: [Anime365Kit.Episode],
  ) -> Bool {
    for anime365Episode in anime365Episodes {
      if anime365Episode.isActive == 1
        && anime365Episode.isFirstUploaded == 1
        && !Anime365Kit.ApiDateDecoder.isEmptyDate(anime365Episode.firstUploadedDateTime)
      {
        return true
      }
    }

    return false
  }
}
