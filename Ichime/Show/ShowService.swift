import Anime365Kit
import Foundation
import JikanApiClient
import OrderedCollections
import ShikimoriApiClient

enum GetShowByIdError: Error {
  case notFoundByMyAnimeListId
}

struct ShowService {
  private let anime365KitFactory: Anime365KitFactory
  private let shikimoriApiClient: ShikimoriApiClient.ApiClient
  private let shikimoriGraphQLClient: ShikimoriApiClient.GraphQLClient
  private let jikanApiClient: JikanApiClient.ApiClient

  init(
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

  func getShowIdByMyAnimeListId(_ myAnimeListId: Int) async throws -> Int {
    let seriesItems = try await anime365KitFactory.createApiClient().listSeries(myAnimeListId: myAnimeListId)

    guard let series = seriesItems.first else {
      throw GetShowByIdError.notFoundByMyAnimeListId
    }

    return series.id
  }

  func getAllShowCovers(_ myAnimeListId: Int) async throws -> [URL] {
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

  func getShowDetails(showId: Int) async throws -> (ShowDetails) {
    let anime365Series = try await anime365KitFactory.createApiClient().getSeries(
      seriesId: showId
    )

    async let shikimoriAnimeFuture = self.shikimoriApiClient.getAnimeById(
      animeId: anime365Series.myAnimeListId
    )

    async let jikanAnimeFuture = self.jikanApiClient.getAnimeFullById(
      id: anime365Series.myAnimeListId
    )

    let shikimoriAnime = try? await shikimoriAnimeFuture
    let jikanAnime = try? await jikanAnimeFuture

    return
      (.init(
        anime365Series: anime365Series,
        shikimoriAnime: shikimoriAnime,
        shikimoriBaseUrl: self.shikimoriApiClient.baseUrl,
        jikanAnime: jikanAnime
      ))
  }

  func getOngoings(
    offset: Int,
    limit: Int
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

  func getTopScored(
    offset: Int,
    limit: Int
  ) async throws -> OrderedSet<ShowPreview> {
    let apiResponse = try await anime365KitFactory.createApiClient().listSeries(
      limit: limit,
      offset: offset
    )

    return .init(apiResponse.map { .init(anime365Series: $0) })
  }

  func getMostPopular(
    page: Int,
    limit: Int
  ) async throws -> OrderedSet<ShowPreviewShikimori> {
    let response = try await shikimoriGraphQLClient.getPreviews(
      page: page,
      limit: limit,
      order: "popularity",
      censored: true
    )

    return .init(
      response.animes.compactMap {
        ShowPreviewShikimori(
          graphqlAnimePreview: $0,
        )
      }
    )
  }

  func getNextSeason(
    page: Int,
    limit: Int
  ) async throws -> OrderedSet<ShowPreviewShikimori> {
    let showSeasonService = ShowSeasonService()
    let nextSeason = showSeasonService.getRelativeSeason(shift: ShowSeasonService.NEXT_SEASON)

    let response = try await shikimoriGraphQLClient.getPreviews(
      page: page,
      limit: limit,
      order: "popularity",
      season: "\(nextSeason.calendarSeason.getShikimoriApiName())_\(nextSeason.year)",
      censored: true
    )

    return .init(
      response.animes.compactMap {
        ShowPreviewShikimori(
          graphqlAnimePreview: $0,
        )
      }
    )
  }

  func getRandom(
    page: Int,
    limit: Int
  ) async throws -> OrderedSet<ShowPreviewShikimori> {
    let response = try await shikimoriGraphQLClient.getPreviews(
      page: page,
      limit: limit,
      order: "random",
      censored: true
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
  func getSeason(
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

  func getRelatedShows(
    myAnimeListId: Int
  ) async throws -> OrderedSet<GroupedRelatedShows> {
    let response = try await self.shikimoriGraphQLClient.getRelated(id: myAnimeListId)

    if response.animes.isEmpty {
      return .init()
    }

    return self.convertShikimoriRelationsToGroupedRelatedShows(response.animes[0].related)
  }

  func getScreenshots(
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

  func getCharacters(myAnimeListId: Int) async throws -> OrderedSet<CharacterInfo> {
    let jikanCharacterRoles = try await self.jikanApiClient.getAnimeCharacters(
      id: myAnimeListId
    )

    return .init(jikanCharacterRoles.map { .init(fromJikanCharacterRole: $0) })
  }

  func getStaffMembers(myAnimeListId: Int) async throws -> OrderedSet<StaffMember> {
    let jikanStaffMembers = try await self.jikanApiClient.getAnimeStaff(
      id: myAnimeListId
    )

    return .init(jikanStaffMembers.map { .init(fromJikanStaffMember: $0) })
  }

  func getStudio(
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

  func getByGenre(
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

  func searchShows(
    searchQuery: String,
    offset: Int,
    limit: Int
  ) async throws -> OrderedSet<ShowPreview> {
    let apiResponse = try await anime365KitFactory.createApiClient().listSeries(
      query: searchQuery,
      limit: limit,
      offset: offset
    )

    return .init(apiResponse.map { .init(anime365Series: $0) })
  }

  private func convertShikimoriRelationsToGroupedRelatedShows(
    _ shikimoriRelations: [ShikimoriApiClient.GraphQLAnimeWithRelations.Relation]
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
