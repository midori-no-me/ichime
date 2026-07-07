import Anime365Kit
import Foundation
import IchimeAnime365
import IchimePreferences
import JikanApiClient
import OrderedCollections
import ShikimoriApiClient

public enum GetShowByIdError: Error, Sendable {
  case notFoundByMyAnimeListId
}

public struct ShowService: Sendable {
  private let anime365KitFactory: Anime365KitFactory
  private let shikimoriApiClient: ShikimoriApiClient.ApiClient
  private let shikimoriGraphQLClient: ShikimoriApiClient.GraphQLClient
  private let jikanApiClient: JikanApiClient.ApiClient

  public init(
    anime365KitFactory: Anime365KitFactory,
    shikimoriApiClient: ShikimoriApiClient.ApiClient,
    shikimoriGraphQLClient: ShikimoriApiClient.GraphQLClient,
    jikanApiClient: JikanApiClient.ApiClient
  ) {
    self.anime365KitFactory = anime365KitFactory
    self.shikimoriApiClient = shikimoriApiClient
    self.shikimoriGraphQLClient = shikimoriGraphQLClient
    self.jikanApiClient = jikanApiClient
  }

  public func getShowIdByMyAnimeListId(_ myAnimeListId: Int) async throws -> Int {
    let seriesItems = try await anime365KitFactory.createApiClient().listSeries(myAnimeListId: myAnimeListId)

    guard let series = seriesItems.first else {
      throw GetShowByIdError.notFoundByMyAnimeListId
    }

    return series.id
  }

  public func getAllShowCovers(_ myAnimeListId: Int) async throws -> [URL] {
    let pictures = try await jikanApiClient.getAnimePictures(id: myAnimeListId)

    var coverUrls: [URL] = []

    for picture in pictures {
      guard let coverUrl = picture.jpg.image_url else {
        continue
      }

      coverUrls.append(coverUrl)
    }

    return coverUrls
  }

  public func getShowDetails(showId: Int) async throws -> (ShowDetails) {
    let anime365Series = try await anime365KitFactory.createApiClient().getSeries(
      seriesId: showId
    )

    let shikimoriAnime = try? await self.shikimoriApiClient.getAnimeById(
      animeId: anime365Series.myAnimeListId
    )

    let jikanAnime = try? await self.jikanApiClient.getAnimeFullById(
      id: anime365Series.myAnimeListId
    )

    return
      (.init(
        anime365Series: anime365Series,
        shikimoriAnime: shikimoriAnime,
        shikimoriBaseUrl: self.shikimoriApiClient.baseUrl,
        jikanAnime: jikanAnime
      ))
  }

  public func getOngoings(
    offset: Int,
    limit: Int,
  ) async throws -> OrderedSet<ShowPreview> {
    let visibilityOna = OngoingsVisibilityOna.get()

    var hiddenTypes: Set<Anime365Kit.SeriesType> = [
      Anime365Kit.SeriesType.pv,
      Anime365Kit.SeriesType.cm,
      Anime365Kit.SeriesType.music,
    ]

    if visibilityOna == .hide {
      hiddenTypes.insert(Anime365Kit.SeriesType.ona)
    }

    var chips = [
      "isAiring": "1",
      "isActive": "1",
      "type!": hiddenTypes.map(\.rawValue).joined(separator: ","),
    ]

    let visibilityOld = OngoingsVisibilityOld.get()

    if visibilityOld == .hide {
      let seasonYearAgo = ShowSeasonService().getRelativeSeason(shift: -4)
      let currentSeason = ShowSeasonService().getRelativeSeason(shift: ShowSeasonService.CURRENT_SEASON)

      chips["yearseason"] =
        "\(seasonYearAgo.calendarSeason.getAnime365ApiName())_\(seasonYearAgo.year)-\(currentSeason.calendarSeason.getAnime365ApiName())_\(currentSeason.year)"
    }

    let apiResponse = try await anime365KitFactory.createApiClient().listSeries(
      limit: limit,
      offset: offset,
      chips: chips
    )

    return .init(apiResponse.map { .init(anime365Series: $0) })
  }

  public func getReleasedInYear(
    year: Int,
    offset: Int,
    limit: Int,
  ) async throws -> OrderedSet<ShowPreview> {
    let chips = [
      "yearseason": String(year)
    ]

    let apiResponse = try await anime365KitFactory.createApiClient().listSeries(
      limit: limit,
      offset: offset,
      chips: chips,
    )

    return .init(apiResponse.map { .init(anime365Series: $0) })
  }

  public func getTopScored(
    offset: Int,
    limit: Int
  ) async throws -> OrderedSet<ShowPreview> {
    let apiResponse = try await anime365KitFactory.createApiClient().listSeries(
      limit: limit,
      offset: offset
    )

    return .init(apiResponse.map { .init(anime365Series: $0) })
  }

  public func getMostPopular(
    page: Int,
    limit: Int,
    adultOnly: Bool,
  ) async throws -> OrderedSet<ShowPreviewShikimori> {
    let response = try await shikimoriGraphQLClient.getPreviews(
      page: page,
      limit: limit,
      order: "popularity",
      censored: !adultOnly,
      rating: adultOnly ? "rx" : nil,
    )

    return .init(
      response.animes.compactMap {
        ShowPreviewShikimori(
          graphqlAnimePreview: $0,
        )
      }
    )
  }

  public func getMostAnticipated(
    page: Int,
    limit: Int,
    adultOnly: Bool,
  ) async throws -> OrderedSet<ShowPreviewShikimori> {
    let response = try await shikimoriGraphQLClient.getPreviews(
      page: page,
      limit: limit,
      order: "popularity",
      censored: !adultOnly,
      rating: adultOnly ? "rx" : nil,
      status: "anons",
    )

    return .init(
      response.animes.compactMap {
        ShowPreviewShikimori(
          graphqlAnimePreview: $0,
        )
      }
    )
  }

  public func getNextSeason(
    page: Int,
    limit: Int,
    adultOnly: Bool,
  ) async throws -> OrderedSet<ShowPreviewShikimori> {
    let showSeasonService = ShowSeasonService()
    let nextSeason = showSeasonService.getRelativeSeason(shift: ShowSeasonService.NEXT_SEASON)

    let response = try await shikimoriGraphQLClient.getPreviews(
      page: page,
      limit: limit,
      order: "popularity",
      season: "\(nextSeason.calendarSeason.getShikimoriApiName())_\(nextSeason.year)",
      censored: !adultOnly,
      rating: adultOnly ? "rx" : nil,
    )

    return .init(
      response.animes.compactMap {
        ShowPreviewShikimori(
          graphqlAnimePreview: $0,
        )
      }
    )
  }

  public func getRandom(
    page: Int,
    limit: Int,
    adultOnly: Bool,
  ) async throws -> OrderedSet<ShowPreviewShikimori> {
    let response = try await shikimoriGraphQLClient.getPreviews(
      page: page,
      limit: limit,
      order: "random",
      censored: !adultOnly,
      rating: adultOnly ? "rx" : nil,
    )

    return .init(
      response.animes.compactMap {
        ShowPreviewShikimori(
          graphqlAnimePreview: $0,
        )
      }
    )
  }

  // periphery:ignore
  public func getSeason(
    offset: Int,
    limit: Int,
    airingSeason: AiringSeason
  ) async throws -> [ShowPreview] {
    let apiResponse = try await anime365KitFactory.createApiClient().listSeries(
      limit: limit,
      offset: offset,
      chips: [
        "yearseason": "\(airingSeason.calendarSeason.getAnime365ApiName())_\(airingSeason.year)"
      ]
    )

    return apiResponse.map { .init(anime365Series: $0) }
  }

  public func getRelatedShows(
    myAnimeListId: Int
  ) async throws -> OrderedSet<GroupedRelatedShows> {
    let response = try await self.shikimoriGraphQLClient.getRelated(id: myAnimeListId)

    if response.animes.isEmpty {
      return .init()
    }

    return self.convertShikimoriRelationsToGroupedRelatedShows(response.animes[0].related)
  }

  public func getScreenshots(
    myAnimeListId: Int
  ) async throws -> OrderedSet<URL> {
    let response = try await self.shikimoriGraphQLClient.getScreenshots(id: myAnimeListId)

    if response.animes.isEmpty {
      return .init()
    }

    return .init(
      response.animes[0].screenshots.map { screenshot in
        screenshot.originalUrl
      }
    )
  }

  public func getCharacters(myAnimeListId: Int) async throws -> OrderedSet<CharacterInfo> {
    let response = try await self.shikimoriGraphQLClient.getCharacters(id: myAnimeListId)

    if response.animes.isEmpty {
      return .init()
    }

    return .init(response.animes[0].characterRoles.map { .init(fromShikimoriCharacterRole: $0) })
  }

  public func getStaffMembers(myAnimeListId: Int) async throws -> OrderedSet<StaffMember> {
    let response = try await self.shikimoriGraphQLClient.getStaff(id: myAnimeListId)

    if response.animes.isEmpty {
      return .init()
    }

    return .init(response.animes[0].personRoles.map { .init(fromShikimoriPersonRole: $0) })
  }

  public func getStudio(
    offset: Int,
    limit: Int,
    studioId: Int
  ) async throws -> [ShowPreview] {
    let apiResponse = try await anime365KitFactory.createApiClient().listSeries(
      limit: limit,
      offset: offset,
      chips: [
        "studio": String(studioId)
      ]
    )

    return apiResponse.map { .init(anime365Series: $0) }
  }

  public func getByGenre(
    offset: Int,
    limit: Int,
    genreIds: [Int]
  ) async throws -> [ShowPreview] {
    let apiResponse = try await anime365KitFactory.createApiClient().listSeries(
      limit: limit,
      offset: offset,
      chips: [
        "genre@":
          genreIds
          .map { genreId in String(genreId) }
          .joined(separator: ",")
      ]
    )

    return apiResponse.map { .init(anime365Series: $0) }
  }

  public func searchShows(
    searchQuery: String,
    page: Int,
    limit: Int,
    adultOnly: Bool
  ) async throws -> OrderedSet<ShowPreviewShikimori> {
    let apiResponse = try await shikimoriGraphQLClient.getPreviews(
      page: page,
      limit: limit,
      censored: !adultOnly,
      rating: adultOnly ? "rx" : nil,
      search: searchQuery,
    )

    return .init(apiResponse.animes.compactMap { ShowPreviewShikimori(graphqlAnimePreview: $0) })
  }

  private func convertShikimoriRelationsToGroupedRelatedShows(
    _ shikimoriRelations: [ShikimoriApiClient.GetRelatedResponse.AnimeFields.Relation]
  ) -> OrderedSet<GroupedRelatedShows> {
    var relationTitleToRelatedShows: [ShowRelationKind: [RelatedShow]] = [:]

    for shikimoriRelation in shikimoriRelations {
      guard let relatedShow = RelatedShow(fromShikimoriRelation: shikimoriRelation) else {
        continue
      }

      relationTitleToRelatedShows[relatedShow.relationKind, default: []].append(relatedShow)
    }

    var relatedShowsGroups: [GroupedRelatedShows] = []

    for (relationType, relatedShows) in relationTitleToRelatedShows {
      relatedShowsGroups.append(
        .init(
          relationKind: relationType,
          relatedShows: .init(relatedShows)
        )
      )
    }

    relatedShowsGroups.sort(by: { $0.relationKind.priority > $1.relationKind.priority })

    return .init(relatedShowsGroups)
  }
}
