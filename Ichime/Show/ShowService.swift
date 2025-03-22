import Anime365ApiClient
import Foundation
import JikanApiClient
import ShikimoriApiClient

enum ShowNotFoundError: Error {
  case notFoundByMyAnimeListId
}

struct ShowService {
  private let anime365ApiClient: Anime365ApiClient.ApiClient
  private let shikimoriApiClient: ShikimoriApiClient.ApiClient
  private let jikanApiClient: JikanApiClient.ApiClient
  private let momentsService: MomentService

  init(
    anime365ApiClient: Anime365ApiClient.ApiClient,
    shikimoriApiClient: ShikimoriApiClient.ApiClient,
    jikanApiClient: JikanApiClient.ApiClient,
    momentsService: MomentService
  ) {
    self.anime365ApiClient = anime365ApiClient
    self.shikimoriApiClient = shikimoriApiClient
    self.jikanApiClient = jikanApiClient
    self.momentsService = momentsService
  }

  func getShowIdByMyAnimeListId(_ myAnimeListId: Int) async throws -> Int {
    let seriesItems = try await anime365ApiClient.listSeries(myAnimeListId: myAnimeListId)

    guard let series = seriesItems.first else {
      throw ShowNotFoundError.notFoundByMyAnimeListId
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

  func getFullShow(showId: Int) async throws -> ShowFull {
    let anime365Series = try await anime365ApiClient.getSeries(
      seriesId: showId
    )

    async let momentsFuture = self.momentsService.getShowMoments(showId: showId, page: 1)

    async let shikimoriAnimeFuture = self.shikimoriApiClient.getAnimeById(
      animeId: anime365Series.myAnimeListId
    )

    async let shikimoriScreenshotsFuture = self.shikimoriApiClient.getAnimeScreenshotsById(
      animeId: anime365Series.myAnimeListId
    )

    async let shikimoriRelationsFuture = self.shikimoriApiClient.getAnimeRelatedById(
      animeId: anime365Series.myAnimeListId
    )

    async let jikanCharactersFuture = self.jikanApiClient.getAnimeCharacters(
      id: anime365Series.myAnimeListId
    )

    async let jikanStaffMembersFuture = self.jikanApiClient.getAnimeStaff(
      id: anime365Series.myAnimeListId
    )

    let moments = (try? await momentsFuture) ?? []
    let shikimoriAnime = try? await shikimoriAnimeFuture
    let shikimoriScreenshots = (try? await shikimoriScreenshotsFuture) ?? []
    let shikimoriRelations = (try? await shikimoriRelationsFuture) ?? []
    let jikanCharacters = (try? await jikanCharactersFuture) ?? []
    let jikanStaffMembers = (try? await jikanStaffMembersFuture) ?? []

    return ShowFull.create(
      anime365Series: anime365Series,
      shikimoriAnime: shikimoriAnime,
      shikimoriScreenshots: shikimoriScreenshots,
      shikimoriBaseUrl: self.shikimoriApiClient.baseUrl,
      jikanCharacterRoles: jikanCharacters,
      jikanStaffMembers: jikanStaffMembers,
      moments: moments,
      relatedShows: self.convertShikimoriRelationsToGroupedRelatedShows(shikimoriRelations)
    )
  }

  func getOngoings(
    offset: Int,
    limit: Int
  ) async throws -> [ShowPreview] {
    let apiResponse = try await anime365ApiClient.listSeries(
      limit: limit,
      offset: offset,
      chips: [
        "isAiring": "1",
        "isActive": "1",
      ]
    )

    return apiResponse.map { .init(anime365Series: $0) }
  }

  func getTopScored(
    offset: Int,
    limit: Int
  ) async throws -> [ShowPreview] {
    let apiResponse = try await anime365ApiClient.listSeries(
      limit: limit,
      offset: offset
    )

    return apiResponse.map { .init(anime365Series: $0) }
  }

  func getMostPopular(
    page: Int,
    limit: Int
  ) async throws -> [ShowPreviewShikimori] {
    let shikimoriAnimes = try await shikimoriApiClient.listAnimes(
      page: page,
      limit: limit,
      order: "popularity"
    )

    return shikimoriAnimes.map {
      .init(
        anime: $0,
        shikimoriBaseUrl: self.shikimoriApiClient.baseUrl
      )
    }
  }

  func getNextSeason(
    page: Int,
    limit: Int
  ) async throws -> [ShowPreviewShikimori] {
    let showSeasonService = ShowSeasonService()
    let nextSeason = showSeasonService.getRelativeSeason(shift: ShowSeasonService.NEXT_SEASON)

    let shikimoriAnimes = try await shikimoriApiClient.listAnimes(
      page: page,
      limit: limit,
      order: "popularity",
      season: "\(nextSeason.calendarSeason.getApiName())_\(nextSeason.year)"
    )

    return shikimoriAnimes.map {
      .init(
        anime: $0,
        shikimoriBaseUrl: self.shikimoriApiClient.baseUrl
      )
    }
  }

  func getSeason(
    offset: Int,
    limit: Int,
    airingSeason: AiringSeason
  ) async throws -> [ShowPreview] {
    let apiResponse = try await anime365ApiClient.listSeries(
      limit: limit,
      offset: offset,
      chips: [
        "yearseason": "\(airingSeason.calendarSeason.getApiName())_\(airingSeason.year)"
      ]
    )

    return apiResponse.map { .init(anime365Series: $0) }
  }

  func getByGenre(
    offset: Int,
    limit: Int,
    genreIds: [Int]
  ) async throws -> [ShowPreview] {
    let apiResponse = try await anime365ApiClient.listSeries(
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
  ) async throws -> [ShowPreview] {
    let apiResponse = try await anime365ApiClient.listSeries(
      query: searchQuery,
      limit: limit,
      offset: offset
    )

    return apiResponse.map { .init(anime365Series: $0) }
  }

  private func convertShikimoriRelationsToGroupedRelatedShows(
    _ shikimoriRelations: [ShikimoriApiClient.Relation]
  ) -> [GroupedRelatedShows] {
    var relationTitleToRelatedShows: [ShowRelationKind: [RelatedShow]] = [:]

    for shikimoriRelation in shikimoriRelations {
      guard
        let relatedShow = RelatedShow.createValid(
          shikimoriRelation: shikimoriRelation,
          shikimoriBaseUrl: self.shikimoriApiClient.baseUrl
        )
      else {
        continue
      }

      relationTitleToRelatedShows[relatedShow.relationKind, default: []].append(relatedShow)
    }

    var relatedShowsGroups: [GroupedRelatedShows] = []

    for (relationType, relatedShows) in relationTitleToRelatedShows {
      relatedShowsGroups.append(
        .init(
          relationKind: relationType,
          relatedShows: relatedShows
        )
      )
    }

    relatedShowsGroups.sort(by: { $0.relationKind.priority > $1.relationKind.priority })

    return relatedShowsGroups
  }
}
