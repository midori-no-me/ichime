import Anime365ApiClient
import Foundation

func convertApiDateStringToDate(string: String, withFormat format: String = "yyyy-MM-dd HH:mm:ss")
  -> Date?
{
  let dateFormatter = DateFormatter()

  dateFormatter.dateFormat = format

  let date = dateFormatter.date(from: string)

  return date
}

class Anime365Client {
  private let apiClient: Anime365ApiClient

  init(
    apiClient: Anime365ApiClient
  ) {
    self.apiClient = apiClient
  }

  public func getShow(seriesId: Int) async throws -> Show {
    let apiResponse = try await apiClient.sendApiRequest(
      GetSeriesRequest(
        seriesId: seriesId
      )
    )

    return Show.createFromApiSeries(series: apiResponse)
  }

  public func getOngoings(
    offset: Int,
    limit: Int
  ) async throws -> [Show] {
    let airingSeason = ShowSeasonService().getRelativeSeason(shift: -4)

    let apiResponse = try await apiClient.sendApiRequest(
      ListSeriesRequest(
        limit: limit,
        offset: offset,
        chips: [
          "isAiring": "1",
          "isActive": "1",
          "yearseason": "\(airingSeason.calendarSeason.getApiName())_\(airingSeason.year)-",
        ]
      )
    )

    return apiResponse.map { series in
      Show.createFromApiSeries(series: series)
    }
  }

  public func getTop(
    offset: Int,
    limit: Int
  ) async throws -> [Show] {
    let apiResponse = try await apiClient.sendApiRequest(
      ListSeriesRequest(
        limit: limit,
        offset: offset
      )
    )

    return apiResponse.map { series in
      Show.createFromApiSeries(series: series)
    }
  }

  public func getSeason(
    offset: Int,
    limit: Int,
    airingSeason: AiringSeason
  ) async throws -> [Show] {
    let apiResponse = try await apiClient.sendApiRequest(
      ListSeriesRequest(
        limit: limit,
        offset: offset,
        chips: [
          "yearseason": "\(airingSeason.calendarSeason.getApiName())_\(airingSeason.year)"
        ]
      )
    )

    return apiResponse.map { series in
      Show.createFromApiSeries(series: series)
    }
  }

  public func getByGenre(
    offset: Int,
    limit: Int,
    genreIds: [Int]
  ) async throws -> [Show] {
    let apiResponse = try await apiClient.sendApiRequest(
      ListSeriesRequest(
        limit: limit,
        offset: offset,
        chips: [
          "genre@":
            genreIds
            .map { genreId in String(genreId) }
            .joined(separator: ",")
        ]
      )
    )

    return apiResponse.map { series in
      Show.createFromApiSeries(series: series)
    }
  }

  public func getEpisodeTranslations(
    episodeId: Int
  ) async throws -> [Translation] {
    let apiResponse = try await apiClient.sendApiRequest(
      GetEpisodeRequest(
        episodeId: episodeId
      )
    )

    return apiResponse.translations.map { translation in
      Translation.createFromApiResponse(translation: translation)
    }
  }

  public func getShowByEpisodeId(episodeId: Int) async throws -> Show {
    let episodeResponse = try await apiClient.sendApiRequest(
      GetEpisodeRequest(episodeId: episodeId)
    )
    return try await getShow(seriesId: episodeResponse.seriesId)
  }

  public func searchShows(
    searchQuery: String,
    offset: Int,
    limit: Int
  ) async throws -> [Show] {
    let apiResponse = try await apiClient.sendApiRequest(
      ListSeriesRequest(
        query: searchQuery,
        limit: limit,
        offset: offset
      )
    )

    return apiResponse.map { series in
      Show.createFromApiSeries(series: series)
    }
  }

  public func getEpisodeStreamingInfo(
    translationId: Int
  ) async throws -> EpisodeStreamingInfo {
    let apiResponse = try await apiClient.sendApiRequest(
      GetTranslationEmbed(
        translationId: translationId
      )
    )

    return EpisodeStreamingInfo(apiResponse: apiResponse)
  }
}
