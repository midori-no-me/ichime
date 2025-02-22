import Anime365ApiClient
import Foundation

class Anime365Client {
  private let apiClient: Anime365ApiClient.ApiClient

  init(
    apiClient: Anime365ApiClient.ApiClient
  ) {
    self.apiClient = apiClient
  }

  func getSeason(
    offset: Int,
    limit: Int,
    airingSeason: AiringSeason
  ) async throws -> [ShowPreview] {
    let apiResponse = try await apiClient.listSeries(
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

    return apiResponse.map { .init(anime365Series: $0) }
  }

  func searchShows(
    searchQuery: String,
    offset: Int,
    limit: Int
  ) async throws -> [ShowPreview] {
    let apiResponse = try await apiClient.listSeries(
      query: searchQuery,
      limit: limit,
      offset: offset
    )

    return apiResponse.map { .init(anime365Series: $0) }
  }
}
