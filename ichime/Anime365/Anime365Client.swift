//
//  Anime365.swift
//  ichime
//
//  Created by p.flaks on 02.01.2024.
//

import Anime365ApiClient
import Foundation

func convertApiDateStringToDate(string: String, withFormat format: String = "yyyy-MM-dd HH:mm:ss") -> Date? {
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
        let apiResponse = try await apiClient.sendApiRequest(GetSeriesRequest(
            seriesId: seriesId
        ))

        return Show.createFromApiSeries(series: apiResponse)
    }

    public func getOngoings(
        offset: Int,
        limit: Int
    ) async throws -> [Show] {
        let currentDate = Date()
        let currentYear = Calendar.current.component(.year, from: currentDate)
        let previousYear = currentYear - 1
        let currentMonthNumber = Calendar.current.component(.month, from: currentDate)

        let currentAnimeSeason = switch currentMonthNumber {
        case 1, 2, 3: // January, February, March
            "winter"
        case 4, 5, 6: // April, May, June
            "spring"
        case 7, 8, 9: // July, August, September
            "summer"
        default: // October, November, December
            "autumn"
        }

        let apiResponse = try await apiClient.sendApiRequest(ListSeriesRequest(
            limit: limit,
            offset: offset,
            chips: [
                "isAiring": "1",
                "isActive": "1",
                "yearseason": "\(currentAnimeSeason)_\(previousYear)-",
            ]
        ))

        return apiResponse.map { series in
            Show.createFromApiSeries(series: series)
        }
    }

    public func getEpisodeTranslations(
        episodeId: Int
    ) async throws -> [Translation] {
        let apiResponse = try await apiClient.sendApiRequest(ListTranslationsRequest(
            episodeId: episodeId,
            limit: 1000,
            offset: 0
        ))

        return apiResponse.map { translation in
            Translation.createFromApiSeries(translation: translation)
        }
    }

    public func searchShows(
        searchQuery: String,
        offset: Int,
        limit: Int
    ) async throws -> [Show] {
        let apiResponse = try await apiClient.sendApiRequest(ListSeriesRequest(
            query: searchQuery,
            limit: limit,
            offset: offset
        ))

        return apiResponse.map { series in
            Show.createFromApiSeries(series: series)
        }
    }

    public func getEpisodeStreamingInfo(
        translationId: Int
    ) async throws -> EpisodeStreamingInfo {
        let apiResponse = try await apiClient.sendApiRequest(GetTranslationEmbed(
            translationId: translationId
        ))

        return EpisodeStreamingInfo(apiResponse: apiResponse)
    }
}
