import Anime365ApiClient
import Foundation

class Anime365Client {
  private let apiClient: Anime365ApiClient.ApiClient

  init(
    apiClient: Anime365ApiClient.ApiClient
  ) {
    self.apiClient = apiClient
  }

  func getShow(seriesId: Int) async throws -> Show {
    let apiResponse = try await apiClient.getSeries(seriesId: seriesId)

    return Show.createFromApiSeries(series: apiResponse)
  }

  func getOngoings(
    offset: Int,
    limit: Int
  ) async throws -> [Show] {
    let airingSeason = ShowSeasonService().getRelativeSeason(shift: -4)

    let apiResponse = try await apiClient.listSeries(
      limit: limit,
      offset: offset,
      chips: [
        "isAiring": "1",
        "isActive": "1",
        "yearseason": "\(airingSeason.calendarSeason.getApiName())_\(airingSeason.year)-",
      ]
    )

    return apiResponse.map { series in
      Show.createFromApiSeries(series: series)
    }
  }

  func getTop(
    offset: Int,
    limit: Int
  ) async throws -> [Show] {
    let apiResponse = try await apiClient.listSeries(
      limit: limit,
      offset: offset
    )

    return apiResponse.map { series in
      Show.createFromApiSeries(series: series)
    }
  }

  func getSeason(
    offset: Int,
    limit: Int,
    airingSeason: AiringSeason
  ) async throws -> [Show] {
    let apiResponse = try await apiClient.listSeries(
      limit: limit,
      offset: offset,
      chips: [
        "yearseason": "\(airingSeason.calendarSeason.getApiName())_\(airingSeason.year)"
      ]
    )

    return apiResponse.map { series in
      Show.createFromApiSeries(series: series)
    }
  }

  func getByGenre(
    offset: Int,
    limit: Int,
    genreIds: [Int]
  ) async throws -> [Show] {
    let apiResponse = try await apiClient.listSeries(
      limit: limit,
      offset: offset,
      chips: [
        "genre@":
          genreIds
          .map { genreId in String(genreId) }
          .joined(separator: ",")
      ]
    )

    return apiResponse.map { series in
      Show.createFromApiSeries(series: series)
    }
  }

  func getShowByEpisodeId(episodeId: Int) async throws -> Show {
    let episodeResponse = try await apiClient.getEpisode(
      episodeId: episodeId
    )

    return try await self.getShow(seriesId: episodeResponse.seriesId)
  }

  func searchShows(
    searchQuery: String,
    offset: Int,
    limit: Int
  ) async throws -> [Show] {
    let apiResponse = try await apiClient.listSeries(
      query: searchQuery,
      limit: limit,
      offset: offset
    )

    return apiResponse.map { series in
      Show.createFromApiSeries(series: series)
    }
  }
}
