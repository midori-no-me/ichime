import Anime365ApiClient
import Foundation
import JikanApiClient
import ScraperAPI
import ShikimoriApiClient

enum ShowNotFoundError: Error {
  case notFoundByMyAnimeListId
}

struct ShowService {
  private let anime365ApiClient: Anime365ApiClient.ApiClient
  private let shikimoriApiClient: ShikimoriApiClient.ApiClient
  private let jikanApiClient: JikanApiClient.ApiClient
  private let scraperApi: ScraperAPI.APIClient

  init(
    anime365ApiClient: Anime365ApiClient.ApiClient,
    shikimoriApiClient: ShikimoriApiClient.ApiClient,
    jikanApiClient: JikanApiClient.ApiClient,
    scraperApi: ScraperAPI.APIClient
  ) {
    self.anime365ApiClient = anime365ApiClient
    self.shikimoriApiClient = shikimoriApiClient
    self.jikanApiClient = jikanApiClient
    self.scraperApi = scraperApi
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

    async let anime365MomentsFuture = try await self.scraperApi.sendAPIRequest(
      ScraperAPI.Request.GetMomentsByShow(showId: showId, page: 0)
    )

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

    let anime365Moments = (try? await anime365MomentsFuture) ?? []
    let shikimoriAnime = try await shikimoriAnimeFuture
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
      anime365Moments: anime365Moments,
      relatedShows: self.convertShikimoriRelationsToGroupedRelatedShows(shikimoriRelations)
    )
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
